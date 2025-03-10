####2023 Boulder Bleaching Stress Data

## ---- Setup ----
install.packages("readxl")
install.packages("tidyverse")
install.packages("dplyr")
install.packages("tidyr")
install.packages("ggplot2")
install.packages("pals")
install.packages("knitr")
install.packages("quarto")
install.packages("rstatix")
install.packages("plotly")

library("readxl")
library("tidyverse")
library("dplyr")
library("tidyr")
library("ggplot2")
library("RColorBrewer")
library("knitr")
library("quarto")
library("rstatix")
library("plotly")

# Set working directory
setwd("directoryhere")

# Call the Excel workbook and sheet
bleach_sheet = read_excel("excelworkbookhere",
                          sheet = 5)

## ---- Reformat columns ----
colnames(bleach_sheet1)[5] = "Tree_ID"
colnames(bleach_sheet1)[12] = "Temperature_Bleaching"
colnames(bleach_sheet1)[14] = "Running_Total"
colnames(bleach_sheet1)[18] = "Bleaching_Stress"

bleach_sheet1 = bleach_sheet1 %>%
  mutate(Date = as.Date(Date, format = "%Y-%m-%d"))

bleach_sheet1 = bleach_sheet1 %>%
  group_by(Geno, Nursery, Date, Tree_ID)

# Create necessary variables
first_bleaching_date = as.Date("2023-08-31")
start_date = as.Date("2023-08-31")
end_date = as.Date("2024-01-24")

## ---- OL-specific code ----

# Define and join Oil Slick and Something Special data sets
OL = subset(bleach_sheet1, grepl("OL|SS", bleach_sheet1$Nursery))

# Create column for running fragment total
OL_BS = OL %>%
  group_by(Geno) %>%
  mutate(
    start_stock = first(Running_Total),
    fragments_remaining = start_stock + cumsum(if_else(row_number() == 1, 0, Running_Total)),
    percentage_remaining = ((fragments_remaining / start_stock) * 100),
    bleaching_percentage = if_else(is.nan((Bleaching_Stress / fragments_remaining) * 100
    ), 0, (Bleaching_Stress / fragments_remaining) * 100)
  )

# Group columns by species
OL_on_BS = OL_BS %>%
  mutate(
    GenoGroup = case_when(
      grepl("Dcyl", Geno) ~ "Dcyl",
      grepl("Dsto", Geno) ~ "Dsto",
      grepl("Mcav", Geno) ~ "Mcav",
      grepl("Mmea", Geno) ~ "Mmea",
      grepl("Oann", Geno) ~ "Oann",
      grepl("Ofav", Geno) ~ "Ofav",
      grepl("Pstr", Geno) ~ "Pstr",
      TRUE ~ "Other"
    )
  )

# Filter out any genotypes that don't meet criteria
OL_on_BS = OL_on_BS %>%
  filter(Date >= start_date & Date <= end_date) %>%
  group_by(Geno) %>%
  filter(n() > 1 & sum(Bleaching_Stress > 1) > 0) %>%
  ungroup()

## ---- BD-specific code ----

# Define BD data set
BD = subset(bleach_sheet1, grepl("BD", bleach_sheet1$Nursery))

# Create column for running fragment total
BD_BS = BD %>%
  group_by(Geno) %>%
  mutate(
    start_stock = first(Running_Total),
    fragments_remaining = start_stock + cumsum(if_else(row_number() == 1, 0, Running_Total)),
    percentage_remaining = ((fragments_remaining / start_stock) * 100),
    bleaching_percentage = if_else(is.nan((Bleaching_Stress / fragments_remaining) * 100
    ), 0, (Bleaching_Stress / fragments_remaining) * 100)
  )

# Group columns by species
BD_on_BS = BD_BS %>%
  mutate(
    GenoGroup = case_when(
      grepl("Dcyl", Geno) ~ "Dcyl",
      grepl("Dsto", Geno) ~ "Dsto",
      grepl("Mcav", Geno) ~ "Mcav",
      grepl("Mmea", Geno) ~ "Mmea",
      grepl("Oann", Geno) ~ "Oann",
      grepl("Ofav", Geno) ~ "Ofav",
      grepl("Pstr", Geno) ~ "Pstr",
      TRUE ~ "Other"
    )
  )

# Filter out any genotypes that don't meet criteria
BD_on_BS = BD_on_BS %>%
  filter(Date >= start_date & Date <= end_date) %>%
  group_by(Geno) %>%
  filter(n() > 1 & sum(Bleaching_Stress > 1) > 0) %>%
  ungroup()

## ---- ggplot Setup----

# Create a large enough color palette for all valid genotypes
palette1 = brewer.pal(12, "Set1")
palette2 = brewer.pal(8, "Dark2")
palette3 = brewer.pal(9, "Paired")
colors = colorRampPalette(c(palette1, palette2, palette3))(58)

# Give each genotype a distinct color
genotypes = c(
  "Dcyl01",
  "Dcyl02",
  "Dsto02",
  "Dsto04",
  "Dsto06",
  "Mcav01",
  "Mcav02",
  "Mcav03",
  "Mcav04",
  "Mcav05",
  "Mcav06",
  "Mcav07",
  "Mcav08",
  "Mmea02",
  "Mmea03",
  "Mmea04",
  "Mmea05",
  "Mmea06",
  "Mmea07",
  "Mmea08",
  "Mmea09",
  "Mmea10",
  "Mmea11",
  "Mmea12",
  "Oann01",
  "Oann02",
  "Oann03",
  "Oann04",
  "Oann05",
  "Oann06",
  "Oann07",
  "Oann08",
  "Ofav01",
  "Ofav02",
  "Ofav03",
  "Ofav04",
  "Ofav05",
  "Ofav06",
  "Ofav07",
  "Ofav08",
  "Pstr01",
  "Pstr02",
  "Pstr03",
  "Pstr04",
  "Pstr06",
  "Pstr07",
  "Pstr08",
  "Pstr09",
  "Pstr10",
  "Pstr11",
  "Pstr12"
)

# Create variable for list of corresponding geno/color combinations
color_mapping <- setNames(colors[1:length(genotypes)], genotypes)

## ---- ggplots ----

# Oil Slick Bleaching Stress by Total Fragments
OL_BS_total = ggplot(OL_on_BS, aes(y = OL_on_BS$Bleaching_Stress, color = Geno)) +
  geom_line(aes(x = Date), linewidth = 1) +
  geom_point(aes(x = Date, y = Bleaching_Stress), size = 3) +
  labs(x = "Date", y = "Number of Coral Fragments", title = "Bleaching Stress of Coral Fragments in OL Over Time by Fragment Count") +
  scale_x_date(
    date_labels = "%Y-%m-%d",
    breaks = as.Date(c("2023-08-31", "2024-01-24")),
    minor_breaks = seq(as.Date("2023-08-31"), as.Date("2024-01-24"), by = "20 days"),
    limits = c(as.Date("2023-08-31"), as.Date("2024-01-24")),
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(0, max(OL_on_BS$Bleaching_Stress, na.rm = TRUE), by = 2), expand = expansion(mult = c(0, 0.05))) +
  facet_wrap(~ GenoGroup, scales = "free_x", nrow = 2) +
  scale_color_manual(values = color_mapping) +
  geom_hline(
    yintercept = 0,
    linetype = "solid",
    color = "black",
    linewidth = 0.5
  ) +
  geom_vline(
    xintercept = as.Date(OL_on_BS$Bleaching_Stress),
    linetype = "solid",
    color = "black",
    linewidth = 1
  ) +
  theme_minimal() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.spacing = unit(1, "lines"),
    axis.text.x = element_text(angle = 90, hjust = 1),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.75),
    legend.title = element_text(face = "bold", hjust = 0.5)
  ) +
  geom_vline(
    xintercept = as.Date("2023-10-17"),
    linetype = "dashed",
    color = "red",
    linewidth = 1
  )

# Oil Slick Bleaching Stress by Percentage
OL_BS_p = ggplot(OL_on_BS, aes(y = bleaching_percentage, color = Geno)) +
  geom_line(aes(x = Date), linewidth = 1) +
  geom_point(aes(x = Date, y = bleaching_percentage), size = 3) +
  labs(x = "Date", y = "Bleaching Stress Percentage of Coral Fragments", title = "Bleaching Stress of Coral Fragments in OL Over Time by Percentage") +
  scale_x_date(
    date_labels = "%Y-%m-%d",
    breaks = as.Date(c("2023-08-31", "2024-01-24")),
    minor_breaks = seq(as.Date("2023-08-31"), as.Date("2024-01-24"), by = "20 days"),
    limits = c(as.Date("2023-08-31"), as.Date("2024-01-24")),
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(0, max(OL_on_BS$bleaching_percentage, na.rm = TRUE), by = 20), expand = expansion(mult = c(0, 0.05))) +
  facet_wrap(~ GenoGroup) +
  scale_color_manual(values = color_mapping) +
  geom_hline(
    yintercept = 0,
    linetype = "solid",
    color = "black",
    linewidth = 0.5
  ) +
  geom_vline(
    xintercept = as.Date(first_bleaching_date),
    linetype = "solid",
    color = "black",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = as.Date("2023-10-17"),
    linetype = "dashed",
    color = "red",
    linewidth = 1
  ) +
  theme_minimal() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.spacing = unit(1, "lines"),
    axis.text.x = element_text(angle = 90, hjust = 1),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 1),
    legend.title = element_text(face = "bold", hjust = 0.5)
  )

# Buddy Dive Bleaching Stress by Total Fragments
BD_BS_total = ggplot(BD_on_BS, aes(y = BD_on_BS$Bleaching_Stress, color = Geno)) +
  geom_line(aes(x = Date), linewidth = 1) +
  geom_point(aes(x = Date, y = Bleaching_Stress), size = 3) +
  labs(x = "Date", y = "Number of Coral Fragments", title = "Bleaching Stress of Coral Fragments in BD Over Time by Fragment Count") +
  scale_x_date(
    date_labels = "%Y-%m-%d",
    breaks = as.Date(c("2023-08-31", "2024-01-24")),
    minor_breaks = seq(as.Date("2023-08-31"), as.Date("2024-01-24"), by = "20 days"),
    limits = c(as.Date("2023-08-31"), as.Date("2024-01-24")),
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(0, max(BD_on_BS$Bleaching_Stress, na.rm = TRUE), by = 2), expand = expansion(mult = c(0, 0.05))) +
  facet_wrap(~ GenoGroup, scales = "free_x", nrow = 1) +
  scale_color_manual(values = color_mapping) +
  geom_hline(
    yintercept = 0,
    linetype = "solid",
    color = "black",
    linewidth = 0.5
  ) +
  geom_vline(
    xintercept = as.Date(BD_on_BS$Bleaching_Stress),
    linetype = "solid",
    color = "black",
    linewidth = 1
  ) +
  theme_minimal() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.spacing = unit(1, "lines"),
    axis.text.x = element_text(angle = 90, hjust = 1),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.5),
    legend.title = element_text(face = "bold", hjust = 0.5)
  )

# Buddy Dive Bleaching Stress by Percentage
BD_BS_p = ggplot(BD_on_BS, aes(y = bleaching_percentage, color = Geno)) +
  geom_line(aes(x = Date), linewidth = 1) +
  geom_point(aes(x = Date, y = bleaching_percentage), size = 3) +
  labs(x = "Date", y = "Bleaching Stress Percentage of Coral Fragments", title = "Bleaching Stress of Coral Fragments in BD Over Time by Percentage") +
  scale_x_date(
    date_labels = "%Y-%m-%d",
    breaks = as.Date(c("2023-08-31", "2024-01-24")),
    minor_breaks = seq(as.Date("2023-08-31"), as.Date("2024-01-24"), by = "20 days"),
    limits = c(as.Date("2023-08-31"), as.Date("2024-01-24")),
    expand = c(0, 0)
  ) +
  scale_y_continuous(breaks = seq(0, max(BD_on_BS$bleaching_percentage, na.rm = TRUE), by = 20), expand = expansion(mult = c(0, 0.05))) +
  facet_wrap(~ GenoGroup) +
  scale_color_manual(values = color_mapping) +
  geom_hline(
    yintercept = 0,
    linetype = "solid",
    color = "black",
    linewidth = 0.5
  ) +
  geom_vline(
    xintercept = as.Date(first_bleaching_date),
    linetype = "solid",
    color = "black",
    linewidth = 1
  ) +
  theme_minimal() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.spacing = unit(1, "lines"),
    axis.text.x = element_text(angle = 90, hjust = 1),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", hjust = 0.75),
    legend.title = element_text(face = "bold", hjust = 0.5)
  )

# Copyright © 2025 Jason Mirtspoulos and Reef Renewal Foundation Bonaire (RRFB). All Rights Reserved.
# This script and its contents are the intellectual property of the author.
# Unauthorized distribution, reproduction, or use of this material without prior written permission
# from the author is strictly prohibited.

# For inquiries, please contact jason@reefrenewalbonaire.org
