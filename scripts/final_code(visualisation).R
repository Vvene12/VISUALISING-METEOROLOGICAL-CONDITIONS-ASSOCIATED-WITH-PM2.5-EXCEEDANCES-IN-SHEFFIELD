# ------------------------------------------------------------
# 1) Libraries
# ------------------------------------------------------------
library(dplyr)
library(readr)
library(lubridate)
library(stringr)
library(ggplot2)
library(reshape2)
library(viridis)

# ------------------------------------------------------------
# 2) Load data
# ------------------------------------------------------------
openaq_raw    <- read_csv("Openaq.csv")
openmeteo_raw <- read_csv("Openmeteo.csv")

# ------------------------------------------------------------
# 3) Clean OpenAQ (PM2.5)
# ------------------------------------------------------------
openaq_clean <- openaq_raw %>%
  mutate(
    pm25 = str_extract(`PM2.5 particulate matter (Hourly measured)`, "[0-9\\.]+") %>%
      as.numeric(),
    Date = as.Date(Date, format = "%d/%m/%Y"),
    Time = as.character(Time)
  ) %>%
  select(Date, Time, pm25)

# ------------------------------------------------------------
# 4) Clean OpenMeteo (Weather)
# ------------------------------------------------------------
openmeteo_clean <- openmeteo_raw %>%
  mutate(
    Date = as.Date(format(time, "%Y-%m-%d")),
    Time = format(time, "%H:%M:%S")
  ) %>%
  rename(
    temperature_2m       = `temperature_2m (°C)`,
    relative_humidity_2m = `relative_humidity_2m (%)`,
    precipitation        = `precipitation (mm)`,
    surface_pressure     = `surface_pressure (hPa)`,
    wind_speed_10m       = `wind_speed_10m (km/h)`,
    wind_direction_10m   = `wind_direction_10m (°)`
  ) %>%
  select(
    Date, Time,
    temperature_2m,
    relative_humidity_2m,
    precipitation,
    surface_pressure,
    wind_speed_10m,
    wind_direction_10m
  )

# ------------------------------------------------------------
# 5) Merge datasets (hourly alignment)
# ------------------------------------------------------------
sheffield_data <- openaq_clean %>%
  inner_join(openmeteo_clean, by = c("Date", "Time"))

# ------------------------------------------------------------
# 6) Missing values check + cleaning
# ------------------------------------------------------------
cat("\n--- Missing values summary (before cleaning) ---\n")
print(colSums(is.na(sheffield_data)))
cat("\nTotal rows before cleaning:", nrow(sheffield_data), "\n")

sheffield_data_clean <- sheffield_data %>%
  filter(!is.na(pm25))

cat("\n--- Missing values summary (after cleaning) ---\n")
print(colSums(is.na(sheffield_data_clean)))
cat("\nTotal rows after cleaning:", nrow(sheffield_data_clean), "\n")

# ------------------------------------------------------------
# 7) Derived variables and daily summary
# ------------------------------------------------------------
who_24h <- 15  # WHO 2021 24-hour PM2.5 guideline (µg/m³)

plot_df <- sheffield_data_clean %>%
  mutate(
    datetime = ymd_hms(paste(Date, Time), tz = "Europe/London"),
    exceed   = pm25 > who_24h
  )

daily <- plot_df %>%
  mutate(date = as.Date(datetime)) %>%
  group_by(date) %>%
  summarise(
    n_hours    = sum(!is.na(pm25)),
    pm25_daily = mean(pm25, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  filter(n_hours >= 18) %>%
  mutate(exceed_daily = pm25_daily > who_24h)

# For reporting
nrow(daily)
summary(daily$n_hours)
table(daily$exceed_daily)

# ============================================================
# 8) Visualisations
# ============================================================

# ------------------------------------------------------------
# Section 2: PM2.5 by wind speed and temperature
# ------------------------------------------------------------
p_sec2 <- ggplot(plot_df, aes(x = wind_speed_10m, y = pm25, colour = temperature_2m)) +
  geom_point(alpha = 0.35, size = 1) +
  geom_smooth(method = "loess", se = TRUE, colour = "black") +
  geom_hline(yintercept = who_24h, linetype = "dashed",
             colour = "red", linewidth = 0.7) +
  annotate(
    "text",
    x = Inf, y = who_24h,
    label = paste0("WHO 24h = ", who_24h),
    hjust = 1.1, vjust = -0.5,
    colour = "red", size = 3.2
  ) +
  scale_colour_viridis_c(option = "C", name = "Temperature (°C)") +
  labs(
    title = "PM2.5 concentrations by wind speed and temperature",
    x = "Wind speed at 10 m (km/h)",
    y = expression(PM[2.5]~(mu*g/m^3))
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# ------------------------------------------------------------
# Section 3: Daily mean PM2.5 with WHO guideline
# ------------------------------------------------------------
p_sec3 <- ggplot(daily, aes(x = date, y = pm25_daily)) +
  geom_line(linewidth = 0.8, colour = "#2C3E50") +
  geom_hline(yintercept = who_24h, linetype = "dashed",
             colour = "red", linewidth = 0.7) +
  labs(
    title = "Daily mean PM2.5 concentrations with WHO guideline",
    x = "Date",
    y = expression("Daily mean " * PM[2.5]~(mu*g/m^3))
  ) +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# ------------------------------------------------------------
# Section 4: Median PM2.5 across wind speed categories
# ------------------------------------------------------------
breaks_wind <- seq(
  0,
  ceiling(max(plot_df$wind_speed_10m, na.rm = TRUE) / 5) * 5,
  by = 5
)

plot_df_w <- plot_df %>%
  mutate(
    bin_id = cut(
      wind_speed_10m,
      breaks = breaks_wind,
      include.lowest = TRUE,
      labels = FALSE
    )
  ) %>%
  filter(!is.na(bin_id))

wind_binned <- plot_df_w %>%
  group_by(bin_id) %>%
  summarise(
    pm25_median = median(pm25, na.rm = TRUE),
    n           = n(),
    .groups     = "drop"
  ) %>%
  mutate(
    wind_mid = (breaks_wind[bin_id] + breaks_wind[bin_id + 1]) / 2
  )

p_sec4 <- ggplot(wind_binned, aes(x = wind_mid, y = pm25_median)) +
  geom_line(linewidth = 0.9, colour = "black") +
  geom_point(size = 2, colour = "black") +
  geom_hline(yintercept = who_24h, linetype = "dashed",
             colour = "red", linewidth = 0.7) +
  labs(
    title = "Median PM2.5 levels across wind speed categories",
    x = "Wind speed bin midpoint (km/h)",
    y = expression("Median " * PM[2.5]~(mu*g/m^3))
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

# ------------------------------------------------------------
# Section 5: Distribution of PM2.5 by wind speed category
# ------------------------------------------------------------
plot_df2 <- plot_df %>%
  mutate(
    wind_cat = cut(
      wind_speed_10m,
      breaks = c(-Inf, 5, 10, 15, 20, 30, Inf),
      labels = c("<5", "5–10", "10–15", "15–20", "20–30", "30+")
    )
  )

p_sec5 <- ggplot(plot_df2, aes(x = wind_cat, y = pm25)) +
  geom_boxplot(outlier.alpha = 0.25) +
  geom_hline(yintercept = who_24h, linetype = "dashed",
             colour = "red", linewidth = 0.7) +
  labs(
    title = "PM2.5 Distribution by wind speed category",
    x = "Wind speed category (km/h)",
    y = expression(PM[2.5]~(mu*g/m^3))
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))




