library("tidyverse")
library("yarrr")
library("ggrain")
library("jtools")

highBAS <- tibble(read.csv(
  "/home/keanu/projects/hvsm/data/model-stimuli(pmodOrtho_subjectRating)_response/stimuli_pmodOrthoSubjectRating_response_subjectRatingHighBASlowBAS_clusterThresh_0_66_15_PSC_highBAS.csv",
  header = TRUE
)) %>%
  mutate(BAS = "high")
lowBAS <- tibble(read.csv(
  "/home/keanu/projects/hvsm/data/model-stimuli(pmodOrtho_subjectRating)_response/stimuli_pmodOrthoSubjectRating_response_subjectRatingHighBASlowBAS_clusterThresh_0_66_15_PSC_lowBAS.csv",
  header = TRUE
)) %>%
  mutate(BAS = "low")


psc_data <- bind_rows(highBAS, lowBAS) %>%
  pivot_longer(
    cols = c(stimulus, motor),
    names_to = "regressor",
    values_to = "psc"
  )
psc_data$BAS <- as.factor(psc_data$BAS)
psc_data$regressor <- as.factor(psc_data$regressor)
# psc_data$regressor <- as.factor(psc_data$regressor, levels = c(
#     "IB_Like",
#     "IB_Next",
#     "NIB_Like",
#     "NIB_Next",
#     "Motor_Response"
# ))

dir.create("~/hvsm/plots/model-factorialStimResp_motor", showWarnings = FALSE, recursive = TRUE)
regressor_labels <- c(
  "IB_Like" = "Idealised Body - Like",
  "IB_Next" = "Idealised Body - Next",
  "NIB_Like" = "Non-Idealised Body - Like",
  "NIB_Next" = "Non-Idealised Body - Next",
  "Motor_Response" = "Motor Response"
)
regs <- unique(psc_data$regressor)

for (reg in regs) {
  fname <- paste0("psc_", gsub("[^A-Za-z0-9_]", "_", reg), ".svg")
  outpath <- file.path(path.expand("~/hvsm/plots/model-factorialStimResp_motor"), fname)

  svglite::svglite(outpath, width = 4, height = 9)

  pirateplot(
    formula = psc ~ BAS,
    data = psc_data %>% filter(regressor == reg),
    theme = 1,
    pal = c("red", "lightblue"),
    point.o = 1,
    jitter.val = 0.02,
    inf.f.o = 0.3,
    inf.method = "ci",
    inf.disp = "rect",
    main = paste(regressor_labels[reg]),
    xlab = "Body Appreciation Scale (BAS)",
    ylab = "Percent Signal Change (%)",
    cex.lab = 1.2,
    cex.axis = 1.0,
    cex.names = 1.0,
    ylim = c(-0.5, 0.5),
    beside = FALSE
  )

  dev.off()
}

# dir.create(
#     "~/hvsm/plots/model-factorialStimResp_motor",
#     showWarnings = FALSE,
#     recursive = TRUE
# )

# outfile <- file.path(
#     path.expand("~/hvsm/plots/model-factorialStimResp_motor"),
#     "psc_facets_a4_landscape.png"
# )

# regs <- as.character(unique(psc_data$regressor))

# # prefer to drop the Motor_Response regressor to get four facets
# regs_to_plot <- setdiff(regs, "Motor_Response")
# if (length(regs_to_plot) != 4) {
#     regs_to_plot <- regs
# }

# p <- psc_data %>%
#     filter(regressor %in% regs_to_plot) %>%
#     mutate(regressor = factor(regressor, levels = regs_to_plot)) %>%
#     ggplot(aes(x = BAS, y = psc, fill = BAS)) +
#     geom_rain(alpha = 0.6) +
#     facet_wrap(~ regressor, nrow = 1, scales = "free_x") +
#     theme_minimal() +
#     theme(
#         legend.position = "none",
#         axis.title.x = element_text(size = 10),
#         axis.title.y = element_text(size = 10),
#         strip.text = element_text(size = 10)
#     ) +
#     labs(
#         title = "PSC by BAS groups for model regressors",
#         x = "Body Appreciation Scale (BAS)",
#         y = "Percent Signal Change (%)"
#     ) +
#     ylim(-1, 1)

# ggsave(
#     outfile,
#     plot = p,
#     width = 11.69,
#     height = 3.5,
#     units = "in",
#     dpi = 300
# )

# ggplot(psc_data, aes(x = interaction(BAS, event), y = psc)) +
#     geom_boxplot() +
#     labs(
#         title = "PSC by BAS groups for model regressors",
#         x = "Body Appreciation Scale (BAS)",
#         y = "Percent Signal Change (%)"
#     ) +
#     scale_x_discrete(
#         labels = c(
#             "high.stimulus" = "High BAS - Stimulus",
#             "high.response" = "High BAS - Response",
#             "low.stimulus" = "Low BAS - Stimulus",
#             "low.response" = "Low BAS - Response"
#         )
#     ) +
#     theme_minimal()

# ggplot(
#     psc_data %>% filter(event == "stimulus") %>% select(BAS, psc),
#     aes(x = BAS, y = psc, fill = BAS)
# ) +
#     geom_rain()

# ggplot(
#     psc_data %>% filter(event == "response") %>% select(BAS, psc),
#     aes(x = BAS, y = psc, fill = BAS)
# ) +
#     geom_rain(rain.side = "f1x1")

ggplot(
  psc_data %>% filter(regressor == "stimulus"),
  aes(x = BAS, y = psc, fill = BAS)
) +
  geom_rain(alpha = 0.6) +
  theme_apa() +
  labs(
    title = "PSC by BAS groups for model regressors",
    x = "Body Appreciation Scale (BAS)",
    y = "Percent Signal Change (%)"
  ) +
  ylim(-1, 1)

t.test(
  psc ~ BAS,
  data = psc_data %>% filter(regressor == "stimulus")
)

outfile <- file.path(path.expand("~/hvsm"), "psc_stimulus_pirateplot.svg")
dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)
svglite::svglite(outfile, width = 9, height = 16)

pirateplot(
  formula = psc ~ BAS,
  data = psc_data %>% filter(regressor == "stimulus"),
  theme = 1,
  pal = c("red", "lightblue"),
  point.o = 1,
  jitter.val = 0.02,
  inf.f.o = 0.3,
  inf.method = "ci",
  inf.disp = "rect",
  main = "Mean ROI BOLD PSC by BAS group for Stimulus Regressor",
  xlab = "Body Appreciation Scale (BAS)",
  ylab = "BOLD Percent Signal Change (%)",
  cex.lab = 1.2,
  cex.axis = 1.0,
  cex.names = 1.0,
  ylim = c(-0.75, 0.75),
  beside = FALSE
)

dev.off()

ggplot(
  psc_data %>% filter(regressor == "stimulus") %>% select(BAS, psc),
  aes(x = BAS, y = psc, fill = BAS)
) +
  geom_rain() +
  theme_apa() +
  coord_flip()

t.test(psc_data$psc %>% select(psc_data$regressor == "stimulus") %>% select(psc_data$BAS == "high"), psc_data$psc %>% select(psc_data$regressor == "stimulus") %>% select(psc_data$BAS == "low"))

x <- psc_data %>%
  filter(psc_data$regressor == "stimulus" & psc_data$BAS == "high") %>%
  select(psc)
y <- psc_data %>%
  filter(psc_data$regressor == "stimulus" & psc_data$BAS == "low") %>%
  select(psc)
t.test(x, y, paired = FALSE, var.equal = FALSE)
