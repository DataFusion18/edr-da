#' Run EDR in the current directory
#'
#' @details Required arguments (missing from the defaults) are `spectra_list`, `trait.values`, and `datetime`.
#' Other arguments are set to sensible defaults, but can be changed by adding them to `edr_args`.
#' @param edr_args Named list of arguments to EDR. See details.
#' @inheritParams setup_edr
#' @inheritParams exec_in_dir
#' @export
run_edr <- function(dir, edr_args, edr_dir = "edr") {
    # Set defaults
    paths <- list(ed2in = file.path(dir, "ED2IN"),
                  history = file.path(dir, "outputs"))
    edr_inputs <- list(paths = paths,
                       par.wl = 400:2499,
                       nir.wl = 2500,
                       edr.exe.name = "edr",
                       change.history.time = TRUE,
                       output.path = file.path(dir, edr_dir),
                       clean = FALSE)
    edr_inputs <- modifyList(edr_inputs, edr_args)
    do.call(PEcAnRTM::EDR, edr_inputs)
}

#' Setup EDR directory
#'
#' @param edr_exe_path Path to EDR executable, to be linked.
#' @param target_name Target directory name for EDR
#' @inheritParams exec_in_dir
#' @export
setup_edr <- function(dir, edr_exe_path, edr_dir = "edr") {
    edr_dir <- file.path(dir, edr_dir)
    edr_exe_link <- file.path(edr_dir, "edr")
    edr_output_dir <- file.path(edr_dir, "outputs")
    input_ed2in_path <- file.path(dir, "ED2IN")

    dir.create(edr_dir)
    dir.create(edr_output_dir)

    # Link to EDR executable
    .z <- file.remove(edr_exe_link)
    file.symlink(from = edr_exe_path, to = edr_exe_link)
}
