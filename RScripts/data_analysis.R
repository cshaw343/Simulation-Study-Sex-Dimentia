#---- Package loading, options ----
if (!require("pacman")) 
  install.packages("pacman", repos='http://cran.us.r-project.org')

p_load("tidyverse", "here", "survival")

options(scipen = 999) #Standard Notation
options(digits = 6)   #Round to 6 decimal places
options(warn = -1)    #Suppress warnings

#---- Simulation function ----
sex_dem_sim <- function(num_obs){
  
  #---- Generate the data ----
  data <- data_gen(num_obs)
  
  #---- Data by sex ----
  female_data <- data %>% filter(female == 1)
  male_data <- data %>% filter(female == 0)
  
  #---- Cohort size ----
  num_obs <- nrow(data)
  num_females <- nrow(female_data)
  num_males <- nrow(male_data)
  
  #---- Survival probabilities ----
  p_alive <- data %>% 
    dplyr::select(na.omit(variable_names$deathij_varnames)) %>% 
    map_dbl(~sum(. == 0, na.rm = TRUE))/num_obs
  
  #---- Survival probabilities by sex ----
  p_alive_females <- female_data %>%
    dplyr::select(na.omit(variable_names$deathij_varnames)) %>% 
    map_dbl(~sum(. == 0, na.rm = TRUE))/num_females
  
  p_alive_males <- male_data %>%
    dplyr::select(na.omit(variable_names$deathij_varnames)) %>% 
    map_dbl(~sum(. == 0, na.rm = TRUE))/num_males
  
  #---- Conditional survival probabilities ----
  cp_alive <- vector(length = length(na.omit(variable_names$deathij_varnames)))
  alive <- data %>% 
    dplyr::select(variable_names$deathij_varnames[1:num_tests])
  
  for(i in 1:length(cp_alive)){
    if(i == 1){
      cp_alive[i] = 
        sum(alive[, variable_names$deathij_varnames[i]] == 0)/nrow(alive)
    } else{
      alive <- alive[alive[, variable_names$deathij_varnames[i - 1]] == 0, ]
      cp_alive[i] = 
        sum(alive[, variable_names$deathij_varnames[i]] == 0)/nrow(alive)
    }
  }
  
  #---- Conditional survival probabilities by sex ----
  cp_alive_males <- 
    vector(length = length(na.omit(variable_names$deathij_varnames)))
  alive_males <- male_data %>% 
    dplyr::select(variable_names$deathij_varnames[1:num_tests])
  
  for(i in 1:length(cp_alive_males)){
    if(i == 1){
      cp_alive_males[i] = 
        sum(alive_males[, variable_names$deathij_varnames[i]] == 0)/
        nrow(alive_males)
    } else{
      alive_males <- 
        alive_males[
          alive_males[, variable_names$deathij_varnames[i - 1]] == 0, ]
      cp_alive_males[i] = 
        sum(alive_males[, variable_names$deathij_varnames[i]] == 0)/
        nrow(alive_males)
    }
  }
  
  cp_alive_females <- 
    vector(length = length(na.omit(variable_names$deathij_varnames)))
  alive_females <- female_data %>% 
    dplyr::select(variable_names$deathij_varnames[1:num_tests])
  
  for(i in 1:length(cp_alive_females)){
    if(i == 1){
      cp_alive_females[i] = 
        sum(alive_females[, variable_names$deathij_varnames[i]] == 0)/
        nrow(alive_females)
    } else{
      alive_females <- 
        alive_females[
          alive_females[, variable_names$deathij_varnames[i - 1]] == 0, ]
      cp_alive_females[i] = 
        sum(alive_females[, variable_names$deathij_varnames[i]] == 0)/
        nrow(alive_females)
    }
  }
  
  #---- Mortality logHR (F:M) ----
  survival_data <- data[, variable_names$Sij_varnames[1:num_tests]]
  survival_data[survival_data == 5] <- 4.99999
  data[, variable_names$Sij_varnames[1:num_tests]] <- survival_data
  
  simulated_mortality_logHRs <- vector(length = num_tests)
  
  for(i in 1:length(simulated_mortality_logHRs)){
    survtime_name <- paste0("survtime", i - 1, "-", i)
    death_indicator_name <- paste0("death", i - 1, "-", i)
    cox_model <- coxph(Surv(data[, survtime_name], 
                            data[, death_indicator_name]) ~ data$female)
    simulated_mortality_logHRs[i] <- cox_model$coefficients
  }
  
  # #---- Number at risk for dementia by sex + distribution of U ----
  # at_risk_females <- vector(length = num_tests) 
  # at_risk_males <- vector(length = num_tests) 
  # 
  # mean_U_at_risk_females <- vector(length = num_tests) 
  # mean_U_at_risk_males <- vector(length = num_tests) 
  # 
  # #Computing female at_risk
  # for(slot in 1:num_tests){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     death_last_wave <- paste0("death", (slot - 1))
  #   } else {
  #     dem_last_wave <- paste0("dem", (slot - 2), "-", (slot - 1))
  #     death_last_wave <- paste0("death", (slot - 2), "-", (slot - 1))
  #   }
  #   at_risk <- female_data %>% 
  #     dplyr::select(death_last_wave, dem_last_wave, U) %>% 
  #     filter(!! as.name(death_last_wave) != 1 & !! as.name(dem_last_wave) != 1) 
  #   
  #   at_risk_females[slot] = nrow(at_risk)
  #   mean_U_at_risk_females[slot] <- mean(at_risk$U)
  # }
  # 
  # #Computing male at_risk
  # for(slot in 1:num_tests){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     death_last_wave <- paste0("death", (slot - 1))
  #   } else {
  #     dem_last_wave <- paste0("dem", (slot - 2), "-", (slot - 1))
  #     death_last_wave <- paste0("death", (slot - 2), "-", (slot - 1))
  #   }
  #   at_risk <- male_data %>% 
  #     dplyr::select(death_last_wave, dem_last_wave, U) %>% 
  #     filter(!! as.name(death_last_wave) != 1 & 
  #              !! as.name(dem_last_wave) != 1) 
  #   
  #   at_risk_males[slot] = nrow(at_risk)
  #   mean_U_at_risk_males[slot] <- mean(at_risk$U)
  # }
  
  #---- Total dementia incidence rates (5-year bands) ----
  inc_cases <- colSums(data[, variable_names$dem_varnames])
  PY <- colSums(data[, variable_names$contributed_varnames[1:9]])
  sim_rates <- inc_cases[-1]/PY*1000
  
  # #Computing incidence rates
  # for(slot in 1:num_tests){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   } else {
  #     dem_last_wave <- paste0("dem", (slot - 2), "-", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   }
  #   PY_data <- data %>% 
  #     dplyr::select(dem_last_wave, dem_this_wave, contributed) %>% 
  #     filter(!! as.name(dem_last_wave) != 1) 
  #   
  #   sim_rates[slot] = 
  #     round(1000*(sum(PY_data[, dem_this_wave], na.rm = TRUE)/
  #                   sum(PY_data[, contributed], na.rm = TRUE)), 3)
  # }
  
  #---- Dementia incidence cases, rates, and PY by sex (5-year bands) ----
  inc_cases_females <- colSums(female_data[, variable_names$dem_varnames])
  inc_cases_males <- colSums(male_data[, variable_names$dem_varnames])
  
  PY_females <- colSums(female_data[, variable_names$contributed_varnames[1:9]]) 
  PY_males <- colSums(male_data[, variable_names$contributed_varnames[1:9]])
  
  sim_rates_females <- inc_cases_females[-1]/PY_females*1000
  sim_rates_males <- inc_cases_males[-1]/PY_males*1000
  
  # #Computing female incidence cases, rates, PY
  # for(slot in 1:num_tests){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   } else {
  #     dem_last_wave <- paste0("dem", (slot - 2), "-", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   }
  #   PY_data <- female_data %>% 
  #     dplyr::select(dem_last_wave, dem_this_wave, contributed) %>% 
  #     filter(!! as.name(dem_last_wave) != 1) 
  #   
  #   inc_cases_females[slot] = sum(PY_data[, dem_this_wave], na.rm = TRUE)
  #   
  #   PY_females[slot] = sum(PY_data[, contributed], na.rm = TRUE)
  #   
  #   sim_rates_females[slot] = 
  #     round(1000*(sum(PY_data[, dem_this_wave], na.rm = TRUE)/
  #                   sum(PY_data[, contributed], na.rm = TRUE)), 3)
  # }
  # 
  # #Computing male incidence cases and rates
  # for(slot in 1:num_tests){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   } else {
  #     dem_last_wave <- paste0("dem", (slot - 2), "-", (slot - 1))
  #     dem_this_wave <- paste0("dem", (slot - 1), "-", slot)
  #     contributed <- paste0("contributed", (slot - 1), "-", slot)
  #   }
  #   PY_data <- male_data %>% 
  #     dplyr::select(dem_last_wave, dem_this_wave, contributed) %>% 
  #     filter(!! as.name(dem_last_wave) != 1)
  #   
  #   inc_cases_males[slot] = sum(PY_data[, dem_this_wave], na.rm = TRUE)
  #   
  #   PY_males[slot] = sum(PY_data[, contributed], na.rm = TRUE)
  #   
  #   sim_rates_males[slot] = 
  #     round(1000*sum(PY_data[, dem_this_wave], na.rm = TRUE)/
  #             sum(PY_data[, contributed], na.rm = TRUE), 3)
  # }
  # 
  #---- Dementia logIRRs (5-year bands) ----
  IRRs <- sim_rates_females/sim_rates_males
  #simulated_dementia_logIRRs <- log(IRRs)

  simulated_dementia_logIRRs_data <- matrix(nrow = num_tests, ncol = 5)
  #Point estimate
  simulated_dementia_logIRRs_data[, 1] <- log(IRRs)
  #SE calculation for log(IRR)
  simulated_dementia_logIRRs_data[, 2] <-
    sqrt(1/inc_cases_females[-1] + 1/inc_cases_males[-1])
  #95% CI Lower Bound
  simulated_dementia_logIRRs_data[, 3] <-
    simulated_dementia_logIRRs_data[, 1] -
    1.96*simulated_dementia_logIRRs_data[, 2]
  #95% CI Upper Bound
  simulated_dementia_logIRRs_data[, 4] <-
    simulated_dementia_logIRRs_data[, 1] +
    1.96*simulated_dementia_logIRRs_data[, 2]
  #95% CI Coverage
  simulated_dementia_logIRRs_data[, 5] <-
    (simulated_dementia_logIRRs_data[, 3] < 0 &
    simulated_dementia_logIRRs_data[, 4] > 0)*1

  simulated_dementia_logIRRs_data <-
    as.vector(t(simulated_dementia_logIRRs_data))
  
  #---- Dementia incidence cases, rates, and PY by sex (1-year bands) ----
  inc_cases_females_1year <- 
    colSums(female_data[, variable_names_1year$dem_varnames])
  inc_cases_males_1year <- 
    colSums(male_data[, variable_names_1year$dem_varnames])
  
  PY_females_1year <- 
    colSums(female_data[, variable_names_1year$contributed_varnames]) 
  PY_males_1year <- 
    colSums(male_data[, variable_names_1year$contributed_varnames])
  
  sim_rates_females_1year <- inc_cases_females_1year/PY_females_1year*1000
  sim_rates_males_1year <- inc_cases_males_1year/PY_males_1year*1000
  
  # sim_rates_females_1year <- vector(length = num_tests*5) 
  # sim_rates_males_1year <- vector(length = num_tests*5) 
  # 
  # inc_cases_females_1year <- vector(length = num_tests*5)
  # inc_cases_males_1year <- vector(length = num_tests*5)
  # 
  # PY_females_1year <- vector(length = num_tests*5)
  # PY_males_1year <- vector(length = num_tests*5)
  
  # correct_female_PY <-
  #   colSums(female_data[, variable_names_1year$contributed_varnames],
  #           na.rm = TRUE)
  # 
  # correct_male_PY <-
  #   colSums(male_data[, variable_names_1year$contributed_varnames],
  #           na.rm = TRUE)

  # #Computing female incidence cases, rates, PY
  # for(slot in 1:(num_tests*5)){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     dem_this_wave <- paste0("dem", ((slot - 1) + 50), "-", (slot + 50))
  #     contributed <- paste0("contributed", ((slot - 1) + 50), "-", (slot + 50))
  #   } else {
  #     dem_last_wave <- paste0("dem", ((slot - 2) + 50), "-", ((slot - 1) + 50))
  #     dem_this_wave <- paste0("dem", ((slot - 1) + 50), "-", (slot + 50))
  #     contributed <- paste0("contributed", ((slot - 1) + 50), "-", (slot + 50))
  #   }
  #   
  #   PY_data <- female_data %>% 
  #     dplyr::select(dem_last_wave, dem_this_wave, contributed) %>% 
  #     filter(!! as.name(dem_last_wave) == 0 | is.na(!! as.name(dem_last_wave)))
  # 
  #   inc_cases_females_1year[slot] = sum(PY_data[, dem_this_wave], na.rm = TRUE)
  # 
  #   PY_females_1year[slot] = sum(PY_data[, contributed], na.rm = TRUE)
  # }
  # 
  # sim_rates_females_1year <-
  #   round(1000*(inc_cases_females_1year/PY_females_1year), 3)
  # 
  # 
  # #Computing male incidence cases, rates, PY
  # for(slot in 1:(num_tests*5)){
  #   if(slot == 1){
  #     dem_last_wave <- paste0("dem", (slot - 1))
  #     dem_this_wave <- paste0("dem", ((slot - 1) + 50), "-", (slot + 50))
  #     contributed <- paste0("contributed", ((slot - 1) + 50), "-", (slot + 50))
  #   } else {
  #     dem_last_wave <- paste0("dem", ((slot - 2) + 50), "-", ((slot - 1) + 50))
  #     dem_this_wave <- paste0("dem", ((slot - 1) + 50), "-", (slot + 50))
  #     contributed <- paste0("contributed", ((slot - 1) + 50), "-", (slot + 50))
  #   }
  #   
  #   PY_data <- male_data %>%
  #     dplyr::select(dem_last_wave, dem_this_wave, contributed) %>% 
  #     filter(!! as.name(dem_last_wave) == 0 | is.na(!! as.name(dem_last_wave)))
  # 
  #   inc_cases_males_1year[slot] = sum(PY_data[, dem_this_wave], na.rm = TRUE)
  # 
  #   PY_males_1year[slot] = sum(PY_data[, contributed], na.rm = TRUE)
  # }
  # 
  # sim_rates_males_1year <-
  #   round(1000*(inc_cases_males_1year/PY_males_1year), 3)

  # #---- Dementia logIRRs (1-year bands) ----
  IRRs_1year <- sim_rates_females_1year/sim_rates_males_1year
  #simulated_dementia_logIRRs_1yr <- log(IRRs_1year)
  # 
  simulated_dementia_logIRRs_data_1yr <- matrix(nrow = num_tests*5, ncol = 5)
  #Point estimate
  simulated_dementia_logIRRs_data_1yr[, 1] <- log(IRRs_1year)
  #SE calculation for log(IRR)
  simulated_dementia_logIRRs_data_1yr[, 2] <-
    sqrt(1/inc_cases_females_1year + 1/inc_cases_males_1year)
  #95% CI Lower Bound
  simulated_dementia_logIRRs_data_1yr[, 3] <-
    simulated_dementia_logIRRs_data_1yr[, 1] -
    1.96*simulated_dementia_logIRRs_data_1yr[, 2]
  #95% CI Upper Bound
  simulated_dementia_logIRRs_data_1yr[, 4] <-
    simulated_dementia_logIRRs_data_1yr[, 1] +
    1.96*simulated_dementia_logIRRs_data_1yr[, 2]
  #95% CI Coverage
  simulated_dementia_logIRRs_data_1yr[, 5] <-
    (simulated_dementia_logIRRs_data_1yr[, 3] < 0 &
       simulated_dementia_logIRRs_data_1yr[, 4] > 0)*1

  simulated_dementia_logIRRs_data_1yr <-
    as.vector(t(simulated_dementia_logIRRs_data_1yr))
  
  # #---- Dementia logIRRs Poisson Regression ----
  # modeled_dementia_logIRRs <- vector(length = num_tests)
  # poisson_reg_data <- rbind(cbind(rep("1", length(inc_cases_females)),
  #                                 na.omit(variable_names$interval_ages),
  #                                 inc_cases_females, PY_females), 
  #                           cbind(rep("0", length(inc_cases_females)), 
  #                                 na.omit(variable_names$interval_ages),
  #                                 inc_cases_males, PY_males)) %>% 
  #   as.tibble() %>% 
  #   set_colnames(c("female", "age_interval", "inc_cases", "PY")) %>%
  #   mutate_at(c("female", "inc_cases", "PY"), as.numeric) %>%
  #   mutate("logPY" = log(PY))
  # 
  # for(i in 1:length(modeled_dementia_logIRRs)){
  #   model_data <- tibble("female" = c(1, 0), 
  #                        "py_years" = c(PY_females[i], PY_males[i]), 
  #                        "cases" = c(inc_cases_females[i], inc_cases_males[i]), 
  #                        "logPY" = log(c(PY_females[i], PY_males[i])))
  #   
  #   poisson_model_rate <- glm(cases ~ female + offset(logPY), 
  #                             family = poisson(link = "log"), data = model_data)
  #   modeled_dementia_logIRRs[i] <- poisson_model_rate$coefficients["female"]
  # }
  # 
  # #With ages
  # poisson_model_rate <- 
  #   glm(inc_cases ~ female + age_interval + offset(logPY), 
  #       family = poisson(link = "log"), data = poisson_reg_data)
  # 
  # 
  
  # #---- Dementia logHR (F:M) ----
  # simulated_dementia_logHRs_model_data <-
  #   matrix(nrow = num_tests, ncol = 5)
  # 
  # for(i in 1:num_tests){
  #   PY_contributed_name <- paste0("contributed", i - 1, "-", i)
  #   dem_indicator_name <- paste0("dem", i - 1, "-", i)
  #   if(sum(data[, dem_indicator_name], na.rm = TRUE) == 0){
  #     next
  #   } else{
  #     cox_model <- coxph(Surv(data[, PY_contributed_name],
  #                             data[, dem_indicator_name]) ~ data$female)
  #     
  #     simulated_dementia_logHRs_model_data[i, 1:4] <-
  #       c(summary(cox_model)$coefficients[, c(1, 3)], confint(cox_model))
  #   }
  # }
  # 
  # simulated_dementia_logHRs_model_data[, 5] <-
  #   (simulated_dementia_logHRs_model_data[, 3] < 0 &
  #      simulated_dementia_logHRs_model_data[, 4] > 0)*1
  # 
  # simulated_dementia_logHRs_model_data <-
  #   as.vector(t(simulated_dementia_logHRs_model_data))
  # 
  # #---- Total dementia cases (incident + prevalent) ----
  # dem_cases_female <- female_data %>% 
  #   dplyr::select(variable_names$dem_varnames[-1]) %>% 
  #   colSums(na.rm = TRUE) 
  # 
  # dem_cases_male <- male_data %>% 
  #   dplyr::select(variable_names$dem_varnames[-1]) %>% 
  #   colSums(na.rm = TRUE)
  # 
  # #---- Probability of dementia ----
  # #Prevalence of dementia by sex
  # prop_dem_females <- female_data %>% 
  #   dplyr::select(variable_names$dem_varnames[-1]) %>% 
  #   colMeans(na.rm = TRUE) 
  # 
  # prop_dem_males <- male_data %>% 
  #   dplyr::select(variable_names$dem_varnames[-1]) %>% 
  #   colMeans(na.rm = TRUE) 
  
  #---- Dementia types ----
  demented <- data %>% filter(dem == 1) %>% 
    dplyr::select("female", "dem", "dem_Cij", "dem_random", 
                  variable_names$dem_varnames[-1]) %>% 
    mutate("dem_both" = ifelse(dem_Cij == 1 & dem_random == 1, 1, 0))
  
  n_demented_by_age <- demented %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  
  demented_women <- demented %>% filter(female == 1)
  n_demented_by_age_W <- demented_women %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  
  demented_men <- demented %>% filter(female == 0) 
  n_demented_by_age_M <- demented_men %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  
  #---- Random dementia people ----
  #Overall
  n_dem_random <- demented %>% filter(dem_both != 1) %>% 
    summarise_at("dem_random", sum) %>% as.numeric()
  prop_dem_random <- n_dem_random/nrow(demented)
  
  n_dem_random_W <- demented_women %>% filter(dem_both != 1) %>% 
    summarise_at("dem_random", sum) %>% as.numeric()
  prop_dem_random_W <- n_dem_random_W/nrow(demented_women)
  
  n_dem_random_M <- demented_men %>% filter(dem_both != 1) %>% 
    summarise_at("dem_random", sum) %>% as.numeric()
  prop_dem_random_M <- n_dem_random/nrow(demented)
  
  #Age-band specific
  n_dem_random_by_age <- demented %>% 
    filter(dem_random == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_random_by_age <- n_dem_random_by_age/n_demented_by_age
  
  n_dem_random_by_age_W <- demented_women %>% 
    filter(dem_random == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_random_by_age_W <- n_dem_random_by_age_W/n_demented_by_age_W
  
  n_dem_random_by_age_M <- demented_men %>% 
    filter(dem_random == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_random_by_age_M <- n_dem_random_by_age_M/n_demented_by_age_M
  
  #---- Cij dementia people ----
  #Overall
  n_dem_Cij <- demented %>% filter(dem_both != 1) %>% 
    summarise_at("dem_Cij", sum) %>% as.numeric()
  prop_dem_Cij <- n_dem_Cij/nrow(demented)
  
  n_dem_Cij_W <- demented_women %>% filter(dem_both != 1) %>% 
    summarise_at("dem_Cij", sum) %>% as.numeric()
  prop_dem_Cij_W <- n_dem_Cij_W/nrow(demented_women)
  
  n_dem_Cij_M <- demented_men %>% filter(dem_both != 1) %>% 
    summarise_at("dem_Cij", sum) %>% as.numeric()
  prop_dem_Cij_M <- n_dem_Cij_M/nrow(demented_men)
  
  #Age-band specific
  n_dem_Cij_by_age <- demented %>% filter(dem_Cij == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_Cij_by_age <- n_dem_Cij_by_age/n_demented_by_age
  
  n_dem_Cij_by_age_W <- demented_women %>% 
    filter(dem_Cij == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_Cij_by_age_W <- n_dem_Cij_by_age_W/n_demented_by_age_W
  
  n_dem_Cij_by_age_M <- demented_men %>% 
    filter(dem_Cij == 1 & dem_both != 1) %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_Cij_by_age_M <- n_dem_Cij_by_age_M/n_demented_by_age_M
  
  #---- Both types dementia people ----
  dem_both <- demented %>% filter(dem_both == 1)
  dem_both_women <- dem_both %>% filter(female == 1)
  dem_both_men <- dem_both %>% filter(female == 0)
  
  #Overall
  prop_dem_both <- nrow(dem_both)/nrow(demented)
  prop_dem_both_W <- nrow(dem_both_women)/nrow(demented_women)
  prop_dem_both_M <-  nrow(dem_both_men)/nrow(demented_men)
  
  #Age-band specific
  n_dem_both_by_age <- dem_both %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_both_by_age <- n_dem_both_by_age/n_demented_by_age
  
  n_dem_both_by_age_W <- dem_both_women %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_both_by_age_W <- n_dem_both_by_age_W/n_demented_by_age_W
  
  n_dem_both_by_age_M <- dem_both_men %>% 
    dplyr::select(variable_names$dem_varnames[-1]) %>% colSums() 
  prop_dem_both_by_age_M <- n_dem_both_by_age_M/n_demented_by_age_M
  
  #---- Vector to return ----
  results_vec <- c(num_obs, num_females, num_males, p_alive, p_alive_females, 
                   p_alive_males, cp_alive, cp_alive_females, cp_alive_males,
                   simulated_mortality_logHRs, #at_risk_females, 
                   #at_risk_males, 
                   sim_rates, sim_rates_females, sim_rates_males, 
                   inc_cases_females[-1], inc_cases_males[-1], PY_females, 
                   PY_males, 
                   inc_cases_females_1year, inc_cases_males_1year, 
                   PY_females_1year, PY_males_1year,
                   #simulated_dementia_logIRRs, 
                   #simulated_dementia_logIRRs_1yr,
                   simulated_dementia_logIRRs_data, 
                   simulated_dementia_logIRRs_data_1yr,
                   #simulated_dementia_logHRs_model_data, 
                   #dem_cases_female, 
                   #dem_cases_male 
                   #prop_dem_females, prop_dem_males, 
                   #mean_U_at_risk_females, mean_U_at_risk_males, 
                   prop_dem_random, prop_dem_random_W, prop_dem_random_M, 
                   prop_dem_random_by_age, prop_dem_random_by_age_W, 
                   prop_dem_random_by_age_M,
                   prop_dem_Cij, prop_dem_Cij_W, prop_dem_Cij_M, 
                   prop_dem_Cij_by_age, prop_dem_Cij_by_age_W, 
                   prop_dem_Cij_by_age_M, 
                   prop_dem_both, prop_dem_both_W, prop_dem_both_M, 
                   prop_dem_both_by_age, prop_dem_both_by_age_W, 
                   prop_dem_both_by_age_M)
  
  names(results_vec) <- 
    c("num_obs_baseline", "num_females_baseline", 
      "num_males_baseline", 
      variable_names$p_alive_varnames[1:num_tests], 
      variable_names$p_alive_females_varnames[1:num_tests], 
      variable_names$p_alive_males_varnames[1:num_tests],
      variable_names$cp_alive_varnames[1:num_tests], 
      variable_names$cp_alive_females_varnames[1:num_tests], 
      variable_names$cp_alive_males_varnames[1:num_tests],
      variable_names$mortality_logHR_varnames[1:num_tests],
      #variable_names$at_risk_females_varnames[1:num_tests], 
      #variable_names$at_risk_males_varnames[1:num_tests], 
      variable_names$dem_inc_rate_varnames[1:num_tests], 
      variable_names$dem_inc_rate_females_varnames[1:num_tests], 
      variable_names$dem_inc_rate_males_varnames[1:num_tests], 
      variable_names$inc_cases_females_varnames[1:num_tests], 
      variable_names$inc_cases_males_varnames[1:num_tests], 
      variable_names$PY_females_varnames[1:num_tests], 
      variable_names$PY_males_varnames[1:num_tests],
      variable_names_1year$inc_cases_females_varnames, 
      variable_names_1year$inc_cases_males_varnames,
      variable_names_1year$PY_females_varnames, 
      variable_names_1year$PY_males_varnames, 
      #variable_names$logIRR_varnames[1:num_tests], 
      #variable_names_1year$logIRR_varnames,
      t(
        cbind(
          na.omit(variable_names$logIRR_varnames),
          na.omit(variable_names$logIRR_SE_varnames),
          na.omit(variable_names$logIRR_95CI_Lower_varnames),
          na.omit(variable_names$logIRR_95CI_Upper_varnames),
          na.omit(variable_names$logIRR_95CI_Coverage_varnames))) %>%
        as.vector(),
      t(
        cbind(
          variable_names_1year$logIRR_varnames,
          variable_names_1year$logIRR_SE_varnames,
          variable_names_1year$logIRR_95CI_Lower_varnames,
          variable_names_1year$logIRR_95CI_Upper_varnames,
          variable_names_1year$logIRR_95CI_Coverage_varnames)) %>%
        as.vector(),
      # t(
      #   cbind(
      #     na.omit(variable_names$dementia_logHR_varnames),
      #     na.omit(variable_names$dementia_logHR_SE_varnames),
      #     na.omit(variable_names$dementia_logHR_95CI_Lower_varnames),
      #     na.omit(variable_names$dementia_logHR_95CI_Upper_varnames),
      #     na.omit(variable_names$dementia_logHR_95CI_Coverage_varnames))) %>%
      #   as.vector(),
      #variable_names$dem_cases_females_varnames[1:num_tests], 
      #variable_names$dem_cases_males_varnames[1:num_tests] 
      #variable_names$prop_dem_females_varnames[1:num_tests], 
      #variable_names$prop_dem_males_varnames[1:num_tests], 
      #variable_names$mean_U_at_risk_females_varnames[1:num_tests], 
      #variable_names$mean_U_at_risk_males_varnames[1:num_tests]), 
      "prop_dem_random", "prop_dem_random_W", "prop_dem_random_M", 
      variable_names$prop_dem_random_by_age[1:num_tests], 
      variable_names$prop_dem_random_W_by_age[1:num_tests], 
      variable_names$prop_dem_random_M_by_age[1:num_tests],
      "prop_dem_Cij", "prop_dem_Cij_W", "prop_dem_Cij_M", 
      variable_names$prop_dem_Cij_by_age[1:num_tests], 
      variable_names$prop_dem_Cij_W_by_age[1:num_tests], 
      variable_names$prop_dem_Cij_M_by_age[1:num_tests], 
      "prop_dem_both", "prop_dem_both_W", "prop_dem_both_M", 
      variable_names$prop_dem_both_by_age[1:num_tests], 
      variable_names$prop_dem_both_W_by_age[1:num_tests], 
      variable_names$prop_dem_both_M_by_age[1:num_tests]
    )
  
  #---- Return ----
  return(results_vec)
}






  