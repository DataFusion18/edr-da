source("common.R")

pft <- "temperate.Late_Hardwood"
dbh <- 40
lai <- getvar("LAI_CO", dbh, pft)

prospect.param <- c('N' = 1.4,
                    'Cab' = 40,
                    'Car' = 10,
                    'Cw' = 0.01,
                    'Cm' = 0.01)

paths <- getpaths(dbh, pft)
par.wl <- 400:800
nir.wl <- 801:2500
datetime <- ISOdate(2004, 07, 01, 16, 00, 00)

outdir_path <- function(runID) {
    paste("inversion_prior", runID, sep = ".")
}

get_trait_values <- function(param) {
    orient_factor <- param[1]
    clumping_factor <- param[2]
    sla <- param[3]
    b1Bl_large <- param[4]
    b2Bl_large <- param[5]

    trait.values <- list()
    trait.values[[pft]] <- list(orient_factor = orient_factor,
                                      clumping_factor = clumping_factor,
                                      sla = sla,
                                      b1Bl_large = b1Bl_large,
                                      b2Bl_large = b2Bl_large)
    return(trait.values)
}

run_first <- function(inputs) {
    outdir <- outdir_path(inputs$runID)
    dir.create(outdir, showWarnings = FALSE)
    try_link <- link_ed(outdir)

    albedo <- EDR.prospect(prospect.param = prospect.param,
                           prospect.version = 5, 
                           paths = paths,
                           par.wl = par.wl,
                           nir.wl = nir.wl,
                           datetime = datetime,
                           edr.exe.name = "ed_2.1",
                           output.path = outdir)
    return(albedo)
}


invert_model <- function(param, runID = 0) {

    outdir <- outdir_path(runID)
    paths_run <- list(ed2in = NA, history = outdir)

    trait.values <- get_trait_values(param) 

    albedo <- EDR.prospect(prospect.param = prospect.param,
                           prospect.version = 5, 
                           trait.values = trait.values,
                           paths = paths_run,
                           par.wl = par.wl,
                           nir.wl = nir.wl,
                           datetime = datetime,
                           edr.exe.name = "ed_2.1",
                           output.path = outdir, 
                           change.history.time = FALSE)

    return(albedo)
}

# Simulate observation
inits <- c("orient_factor" = 0,
           "clumping_factor" = 0.5,
           "sla" = 40,
           "b1Bl_large" = 0.05,
           "b2Bl_large" = 1.45)

alb <- run_first(list(runID = 0))
obs <- invert_model(inits) + generate.noise()

prior_def <- list(orient_factor = list("unif", list(-0.5, 0.5)),
                  clumping_factor = list("unif", list(0, 1)),
                  sla = list("gamma", list(shape = 5.13, rate = 0.234)),
                  b1Bl_large = list("lnorm", list(log(0.05), 0.1)),
                  b2Bl_large = list("lnorm", list(log(1.45), 0.025)))

prior <- function(params) {
    out <- 0
    for (p in seq_along(prior_def)) {
        func <- get(paste0("d", prior_def[[p]][[1]]))
        out <- out + do.call(func, c(unname(params[p]), 
                                     prior_def[[p]][[2]],
                                     log = TRUE))
    }
    return(out)
}

init_function <- function() {
    out <- sapply(prior_def, 
                  function(x) do.call(get(paste0("r", x[[1]])),
                                      c(1, x[[2]])))
    return(out)
}

param.mins <- c(orient_factor = -0.5,
                clumping_factor = 0,
                sla = 0,
                b1Bl_large = 0,
                b2Bl_large = 0)

param.maxs <- c(orient_factor = 0.5,
                clumping_factor = 1,
                sla = Inf,
                b1Bl_large = Inf,
                b2Bl_large = 1.488) # Hangs if any higher


invert.options <- list(model = invert_model, 
                       run_first = run_first,
                       nchains = 3,
                       inits.function = init_function,
                       prior.function = prior,
                       ngibbs.max = 100000,
                       ngibbs.min = 500,
                       ngibbs.step = 1000,
                       param.mins = param.mins,
                       param.maxs = param.maxs,
                       adapt = 100,
                       adj_min = 0.1,
                       target = 0.234)

runtag <- paste(paste0("dbh", dbh), pft, sep = ".")
fname <- paste("samples", runtag, "rds", sep = ".")
fname_prog <- paste("prog_samples", runtag, "rds", sep = ".")
samples <- invert.auto(observed = obs, 
                       invert.options = invert.options,
                       parallel = TRUE,
                       parallel.output = "output_prior.log",
                       save.samples = fname_prog)
saveRDS(samples, file = fname)
samples.bt <- PEcAn.assim.batch::autoburnin(samples$samples)
png(paste("trace", runtag, "png", sep = "."))
plot(samples.bt)
dev.off()

rawsamps <- do.call(rbind, samples.bt)
png("pairs", runtag, "png", sep = ".")
pairs(rawsamps)
dev.off()
