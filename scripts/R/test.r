data(iris)
library(tidyverse)
library(ggsignif)
library(ggrain)

set.seed(42) # the magic number

iris_subset <- iris[iris$Species %in% c('versicolor', 'virginica'), ]

iris.long <- cbind(
    rbind(iris_subset, iris_subset, iris_subset),
    data.frame(
        time = c(
            rep("t1", dim(iris_subset)[1]),
            rep("t2", dim(iris_subset)[1]),
            rep("t3", dim(iris_subset)[1])
        ),
        id = c(
            rep(1:dim(iris_subset)[1]),
            rep(1:dim(iris_subset)[1]),
            rep(1:dim(iris_subset)[1])
        )
    )
)

# adding .5 and some noise to the versicolor species in t2
iris.long$Sepal.Width[
    iris.long$Species == 'versicolor' & iris.long$time == "t2"
] <- iris.long$Sepal.Width[
    iris.long$Species == 'versicolor' & iris.long$time == "t2"
] +
    .5 +
    rnorm(
        length(iris.long$Sepal.Width[
            iris.long$Species == 'versicolor' & iris.long$time == "t2"
        ]),
        sd = .2
    )
# adding .8 and some noise to the versicolor species in t3
iris.long$Sepal.Width[
    iris.long$Species == 'versicolor' & iris.long$time == "t3"
] <- iris.long$Sepal.Width[
    iris.long$Species == 'versicolor' & iris.long$time == "t3"
] +
    .8 +
    rnorm(
        length(iris.long$Sepal.Width[
            iris.long$Species == 'versicolor' & iris.long$time == "t3"
        ]),
        sd = .2
    )

# now we subtract -.2 and some noise to the virginica species
iris.long$Sepal.Width[
    iris.long$Species == 'virginica' & iris.long$time == "t2"
] <- iris.long$Sepal.Width[
    iris.long$Species == 'virginica' & iris.long$time == "t2"
] -
    .2 +
    rnorm(
        length(iris.long$Sepal.Width[
            iris.long$Species == 'virginica' & iris.long$time == "t2"
        ]),
        sd = .2
    )

# now we subtract -.4 and some noise to the virginica species
iris.long$Sepal.Width[
    iris.long$Species == 'virginica' & iris.long$time == "t3"
] <- iris.long$Sepal.Width[
    iris.long$Species == 'virginica' & iris.long$time == "t3"
] -
    .4 +
    rnorm(
        length(iris.long$Sepal.Width[
            iris.long$Species == 'virginica' & iris.long$time == "t3"
        ]),
        sd = .2
    )

iris.long$Sepal.Width <- round(iris.long$Sepal.Width, 1) # rounding Sepal.Width so t2 data is on the same resolution
iris.long$time <- factor(iris.long$time, levels = c('t1', 't2', 't3'))

ggplot(
    iris.long[
        iris.long$Species == 'versicolor' & iris.long$time %in% c('t1', 't2'),
    ],
    aes(time, Sepal.Width, fill = Species)
) +
    geom_rain(alpha = .5, rain.side = 'f1x1') +
    ggsignif::geom_signif(
        comparisons = list(c("t1", "t2")),
        map_signif_level = TRUE
    ) +
    scale_fill_manual(values = c("darkorange", "darkorange")) +
    theme_classic()

library("tidyverse")
library("yarrr")
library("ggrain")
library("jtools")

# Define list of CSV files with their cluster labels
csv_files <- list(
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_-22_-50_-5_PSC_highBAS.csv",
        BAS = "high",
        cluster = "ibNIB_-22_-50_-5"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_-22_-50_-5_PSC_lowBAS.csv",
        BAS = "low",
        cluster = "ibNIB_-22_-50_-5"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_-27_-77_12_PSC_highBAS.csv",
        BAS = "high",
        cluster = "ibNIB_-27_-77_12"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_-27_-77_12_PSC_lowBAS.csv",
        BAS = "low",
        cluster = "ibNIB_-27_-77_12"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_23_-44_-15_PSC_highBAS.csv",
        BAS = "high",
        cluster = "ibNIB_23_-44_-15"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_23_-44_-15_PSC_lowBAS.csv",
        BAS = "low",
        cluster = "ibNIB_23_-44_-15"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_28_-74_20_PSC_highBAS.csv",
        BAS = "high",
        cluster = "ibNIB_28_-74_20"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/ibNIB_clusterThresh_28_-74_20_PSC_lowBAS.csv",
        BAS = "low",
        cluster = "ibNIB_28_-74_20"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/likeNext_clusterThresh_-4_56_5_PSC_highBAS.csv",
        BAS = "high",
        cluster = "likeNext_-4_56_5"
    ),
    list(
        file = "/home/keanu/projects/hvsm/data/model-factorialStimResp_motor/likeNext_clusterThresh_-4_56_5_PSC_lowBAS.csv",
        BAS = "low",
        cluster = "likeNext_-4_56_5"
    )
)

# Read all CSV files and combine them
psc_data <- map_dfr(csv_files, function(item) {
    read.csv(item$file, header = TRUE) %>%
        as_tibble() %>%
        mutate(
            BAS = item$BAS,
            cluster = item$cluster
        )
}) %>%
    pivot_longer(
        cols = c(IB_Like, IB_Next, Motor_Response, NIB_Like, NIB_Next),
        names_to = "regressor",
        values_to = "psc"
    ) %>%
    mutate(
        BAS = as.factor(BAS),
        regressor = as.factor(regressor),
        cluster = as.factor(cluster)
    )
# psc_data$regressor <- as.factor(psc_data$regressor, levels = c(
#     "IB_Like",
#     "IB_Next",
#     "NIB_Like",
#     "NIB_Next",
#     "Motor_Response"
# ))


  pirateplot(
        formula = psc ~ BAS + regressor,
        data = psc_data %>% filter(regressor != 'Motor_Response'),
        theme = 1,
        pal = c("red", "lightblue"),
        point.o = 1,
        jitter.val = 0.02,
        inf.f.o = 0.3,
        inf.method = "ci",
        inf.disp = "rect",
        main = "PSC by BAS groups for model regressors",
        xlab = "Body Appreciation Scale (BAS)",
        ylab = "Percent Signal Change (%)",
        cex.lab = 1.2,
        cex.axis = 1.0,
        cex.names = 1.0,
        ylim = c(-0.5, 0.5),
        beside = FALSE
    )

t.test(
  x = psc_data %>%
    filter(regressor == "IB_Like", BAS == "high") %>%
    pull(psc),
  y = psc_data %>%
    filter(regressor == "IB_Like", BAS == "low") %>%
    pull(psc),
  paired = FALSE,
  var.equal = FALSE
)
    
t.test(
    psc ~ BAS,
    data = psc_data %>% filter(regressor == 'IB_Next')
)

t.test(
    psc ~ BAS,
    data = psc_data %>% filter(regressor == 'NIB_Like')
)

t.test(
    psc ~ BAS,
    data = psc_data %>% filter(regressor == 'NIB_Next')
)

# dir.create(
#     "~/hvsm/plots/model-factorialStimResp_motor",
#     showWarnings = FALSE,
#     recursive = TRUE
# )
# regressor_labels <- c(
#     "IB_Like" = "Idealised Body - Like",
#     "IB_Next" = "Idealised Body - Next",
#     "NIB_Like" = "Non-Idealised Body - Like",
#     "NIB_Next" = "Non-Idealised Body - Next",
#     "Motor_Response" = "Motor Response"
# )
# regs <- unique(psc_data$regressor)

# for (reg in regs) {
#     fname <- paste0("psc_", gsub("[^A-Za-z0-9_]", "_", reg), ".svg")
#     outpath <- file.path(
#         path.expand("~/hvsm/plots/model-factorialStimResp_motor"),
#         fname
#     )

#     svglite::svglite(outpath, width = 4, height = 9)

#     pirateplot(
#         formula = psc ~ BAS,
#         data = psc_data %>% filter(regressor == reg),
#         theme = 1,
#         pal = c("red", "lightblue"),
#         point.o = 1,
#         jitter.val = 0.02,
#         inf.f.o = 0.3,
#         inf.method = "ci",
#         inf.disp = "rect",
#         main = paste(regressor_labels[reg]),
#         xlab = "Body Appreciation Scale (BAS)",
#         ylab = "Percent Signal Change (%)",
#         cex.lab = 1.2,
#         cex.axis = 1.0,
#         cex.names = 1.0,
#         ylim = c(-0.5, 0.5),
#         beside = FALSE
#     )

#     dev.off()
# }

# # dir.create(
# #     "~/hvsm/plots/model-factorialStimResp_motor",
# #     showWarnings = FALSE,
# #     recursive = TRUE
# # )

# # outfile <- file.path(
# #     path.expand("~/hvsm/plots/model-factorialStimResp_motor"),
# #     "psc_facets_a4_landscape.png"
# # )

# # regs <- as.character(unique(psc_data$regressor))

# # # prefer to drop the Motor_Response regressor to get four facets
# # regs_to_plot <- setdiff(regs, "Motor_Response")
# # if (length(regs_to_plot) != 4) {
# #     regs_to_plot <- regs
# # }

# # p <- psc_data %>%
# #     filter(regressor %in% regs_to_plot) %>%
# #     mutate(regressor = factor(regressor, levels = regs_to_plot)) %>%
# #     ggplot(aes(x = BAS, y = psc, fill = BAS)) +
# #     geom_rain(alpha = 0.6) +
# #     facet_wrap(~ regressor, nrow = 1, scales = "free_x") +
# #     theme_minimal() +
# #     theme(
# #         legend.position = "none",
# #         axis.title.x = element_text(size = 10),
# #         axis.title.y = element_text(size = 10),
# #         strip.text = element_text(size = 10)
# #     ) +
# #     labs(
# #         title = "PSC by BAS groups for model regressors",
# #         x = "Body Appreciation Scale (BAS)",
# #         y = "Percent Signal Change (%)"
# #     ) +
# #     ylim(-1, 1)

# # ggsave(
# #     outfile,
# #     plot = p,
# #     width = 11.69,
# #     height = 3.5,
# #     units = "in",
# #     dpi = 300
# # )

# # ggplot(psc_data, aes(x = interaction(BAS, event), y = psc)) +
# #     geom_boxplot() +
# #     labs(
# #         title = "PSC by BAS groups for model regressors",
# #         x = "Body Appreciation Scale (BAS)",
# #         y = "Percent Signal Change (%)"
# #     ) +
# #     scale_x_discrete(
# #         labels = c(
# #             "high.stimulus" = "High BAS - Stimulus",
# #             "high.response" = "High BAS - Response",
# #             "low.stimulus" = "Low BAS - Stimulus",
# #             "low.response" = "Low BAS - Response"
# #         )
# #     ) +
# #     theme_minimal()

# # ggplot(
# #     psc_data %>% filter(event == "stimulus") %>% select(BAS, psc),
# #     aes(x = BAS, y = psc, fill = BAS)
# # ) +
# #     geom_rain()

# # ggplot(
# #     psc_data %>% filter(event == "response") %>% select(BAS, psc),
# #     aes(x = BAS, y = psc, fill = BAS)
# # ) +
# #     geom_rain(rain.side = "f1x1")

# ggplot(
#     psc_data %>% filter(regressor != "Motor_Response"),
#     aes(x = BAS, y = psc, fill = )
# ) +
#     geom_rain(alpha = 0.6) +
#     theme_apa() +
#     labs(
#         title = "PSC by BAS groups for model regressors",
#         x = "Body Appreciation Scale (BAS)",
#         y = "Percent Signal Change (%)"
#     ) +
#     ylim(-1, 1)

