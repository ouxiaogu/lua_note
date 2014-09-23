-- LUA script for FEM Cal Flow in FEM+ job, all input can be from GUI.
-- Version 2013.09.00

---------------------------------------------------------
--                 Some model options                  --
---------------------------------------------------------
MODELINFO = {}             -- pixel, technode, ...
MASKOPTIONS = {}           -- rangeMA
TCCOPTIONS = {}            -- ambit
RESISTOPTIONS = {addconstraints="qtrFiltSize_ag1=9, qtrFiltSize_ag2=13, qtrFiltSize_am=10,qtrFiltSize_bn=24,qtrFiltSize_bp=13,qtrFiltSize_mg1=10"}         -- qtrFiltSizeXX, tightConstraints, tikParam, ...
ETCHOPTIONS = {}           -- qtrFiltSizeXX, tightConstraints, tikParam, ...

DIFFORDEROPTIONS = {}      -- options for diffraction order computation
DENSITYMAPOPTIONS = {}     -- options for full chip image computation

MYRESISTVARIABLES = {}     -- user-defined resist parameters for lua-terms
                           -- example: { {"my_sigma", 0.1, 0.18}, { "my_shift", 0.02, 0.03}}

---------------------------------------------------------
--   Flare information, flaremap and densitymap        --
---------------------------------------------------------
flareinput = DM.load_flare()
if (flareinput ~= nil) then
    DMAP_file = flareinput.f_param.densitymap
    FMAP_file = flareinput.f_param.flaremap
    PSF_file = flareinput.f_param.flare.PSF.file
    MACHINE_file = flareinput.f_param.flare.default
    MACHINE_type = flareinput.f_param.flare.MachineType
end

---------------------------------------------------------
--      Some useful constants and functions            --
---------------------------------------------------------
BRUTE = 0
SMART = 1

MAXSIMPLEXITERATION = 80
OpticalSmartIteration = 3
SimplexCount = 2

DENSITYTYPE = ""
litholayer = {}

populate = function(a, b, c)  -- a: min, b: max, c: step
    if a > b then
        a, b = b, a
    end
    if c <= 0 then
        c = 1e-3
    end
    points = {}
    while (a <= b + 1e-6) do
        table.insert(points, a)
        a = a + c
    end
    return points
end

---------------------------------------------------------
--                 AppStage function                   --
---------------------------------------------------------
AppStage = function()

    DM.set_model_info(MODELINFO)
    DM.load_resist_from_db()
    resisttemplate = DM.get_resist()

    need_adi_density_map = false
    need_adi_density_map = DM.get_parameter(resisttemplate, "cSLG1") ~= 0 or DM.get_parameter(resisttemplate, "cSLG2") ~= 0
                               or DM.get_parameter(resisttemplate, "cSLG3") ~= 0

    if (need_adi_density_map) then
        DM.run_stage("femprep", "ADI_density_map", {preprocess = "density_map"}, DENSITYMAPOPTIONS)
    end

    resist_search = DM.get_resist_search()
    optical_search = DM.get_optical_search()

    if (optical_search == BRUTE) then
        DM.run_stage("fem+", "TccPrep", {}, {DistributeMode = "optics+fem_d", AppMain = "TccPrep", keeptemptcc = 1})
        DM.run_stage("fem+", "Main", {}, {})
    else
        if (resist_search == BRUTE) then
            for i = 1, OpticalSmartIteration do
                DM.run_stage("fem+", "SmartOptical"..i, {},
                            {AppDone = "SmartIterationDone", first = (i == 1) and 1 or 0, flexflow = 1})
            end
            DM.run_stage("fem+", "SmartFinish", {}, {AppMain = "SmartFinish", flexflow = 1})
        else
            for i = 1, SimplexCount do
                DM.run_stage("fem+", "SimplexResist_"..i, {},
                            {AppDone = "SmartIterationDone", nom_only = 1, flexflow = 1})
                for j = 1, OpticalSmartIteration do
                    first_n = (i == 1 and j == 1) and 1 or 0
                    DM.run_stage("fem+", "SmartOptical_"..i.."_"..j, {},
                                {AppDone = "SmartIterationDone", skip_simplex = 1, first = first_n, flexflow = 1})
                end
            end
            DM.run_stage("fem+", "SmartFinish", {}, {AppMain = "SmartFinish", flexflow = 1})
        end
    end

end
---------------------------------------------------------
--                 AppInit function                    --
---------------------------------------------------------
AppInit = function()
    conds = DM.load_fem_conditions()
    DM.set_model_info(MODELINFO)

    DM.load_masktemplates_from_db()
    DM.set_mask_options(MASKOPTIONS)
    DM.load_exposures_from_db()
    DM.set_tcc_options(TCCOPTIONS)
    DM.load_resist_from_db()
    DM.set_resist_options(RESISTOPTIONS)
    DM.load_variables_from_db()

    orig_gauges = DM.load_gauge_table(conds)
    sems = DM.load_sem_table(conds)
    litholayer = DM.load_litho_layer()

    if (table.getn(MYRESISTVARIABLES) > 0) then
  DM.load_variables(MYRESISTVARIABLES, "RESIST")
    end

end

---------------------------------------------------------
--                TccPrep function                     --
---------------------------------------------------------
TccPrep = function()
    conds = DM.get_cur_fem_conditions()
    tcctemplate = DM.get_exposure()
    masktemplate = DM.get_masktemplate()
    tccs = DM.compute_tcc(tcctemplate, conds, masktemplate)
    DM.add_fem_result(tccs)
end

---------------------------------------------------------
--                AppMain function                     --
---------------------------------------------------------
AppMain = function()
    conds = DM.get_cur_fem_conditions()
    litholayer = DM.load_litho_layer()
    gauges = DM.check_invalid_gauge(orig_gauges)
    resistsearch = DM.get_resist_search()

    tcctemplate = DM.get_exposure()
    masktemplate = DM.get_masktemplate()
    rsttemplate = DM.get_resist()

    if (DM.get_option("nom_only") == 1 and DM.is_nominal() == false) then
        if (flareinput ~= nil) then
            models = DM.create_fem_model(tcctemplate, masktemplate, rsttemplate, flareinput.f_param.flare)
        else
            models = DM.create_fem_model(tcctemplate, masktemplate, rsttemplate)
        end
        DM.add_fem_result(models)
        return
    end

    tccs = DM.compute_tcc(tcctemplate, conds, masktemplate)

    cd = {}
    wcd = {}
    aicd = {}
    ails = {}
    adicd = {}
    semerrors = {}
    DENSITYTYPE = "adi"

    for i, gauge in pairs(gauges) do
        DM.compute_mask_image(gauge, litholayer, masktemplate)
        if (flareinput ~= nil) then
            DM.compute_aerial_image(gauge, litholayer, tccs, masktemplate, FMAP_file)
        else
            DM.compute_aerial_image(gauge, litholayer, tccs, masktemplate)
        end
    end

    ct = DM.compute_ct(gauges, rsttemplate)

    for i,sem in pairs(sems) do
        DM.load_sem_image(sem)
        DM.compute_mask_image(sem, litholayer, masktemplate)
        if (flareinput ~= nil) then
            DM.compute_aerial_image(sem, litholayer, tccs, masktemplate, FMAP_file)
        else
            DM.compute_aerial_image(sem, litholayer, tccs, masktemplate)
        end
        DM.align_sem(sem, rsttemplate)
    end

    if (ct == 0) then
        ct = DM.compute_ct(sems, rsttemplate)
    end

    if (resistsearch == SMART and DM.get_option("skip_simplex") ~= 1) then
            rsttemplate = SIMPLEX_SEARCH(gauges, sems, rsttemplate)
    end

    gauge_signals = {{},{},{},{},{}}
    for j, gauge in ipairs(gauges) do
        DM.load_density(gauge, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(gauge, rsttemplate)

        for m = 1, table.getn(gauge_signals) do
            if (m ~= table.getn(gauge_signals)) then
                for k, v in ipairs(signal[m]) do
                    table.insert(gauge_signals[m], v)
                end
            else
                table.insert(gauge_signals[m], signal[m])
            end
        end
    end

    sem_signals = {{},{},{},{},{}}
    for j,sem in ipairs(sems) do
        DM.load_density(sem, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(sem, rsttemplate)
        for m = 1,table.getn(sem_signals)   do
            for k, v in ipairs(signal[m]) do
                table.insert(sem_signals[m], v)
            end
        end
    end

    rst = DM.search_resist_parms(gauge_signals, rsttemplate, gauges, sem_signals, sems)


    for i, gauge in ipairs(gauges) do
        gaugename = DM.get_gauge_attribute(gauge, "name")
        cd[gaugename] = DM.compute_cd(gauge, rst)
        wcd[gaugename] = DM.get_gauge_attribute(gauge, "wafer_cd")
        aicd[gaugename] = DM.compute_ai_cd(gauge, ct)
        ails[gaugename] = DM.compute_ails(gauge, cd[gaugename])
    end
    errors = DM.compute_error(cd, wcd)
    specerrors = CALC_SPEC_ERROR(gauges, cd, wcd)

    for i,sem in pairs(sems) do
        semname = DM.get_sem_attribute(sem, "name")
        semerrors[semname] = DM.compute_sem_error(sem, rst)
    end

    if (flareinput ~= nil) then
        models = DM.create_fem_model(tccs, masktemplate, rst, flareinput.f_param.flare)
    else
        models = DM.create_fem_model(tccs, masktemplate, rst)
    end

    DM.add_fem_result(models, errors, semerrors, specerrors)
    DM.add_fem_result(aicd, "ai_cd")
    DM.add_fem_result(ails, "ils")

end

---------------------------------------------------------
--            Optical Smart Search Functions           --
---------------------------------------------------------
SmartIterationDone = function()
    resultgroups = DM.get_result_by_brute_search()
    next_points = {}
    for i, results in ipairs(resultgroups) do
      next_point = DM.find_next_smart_point(results, "Result_Pool")
        if (next_point ~= nil) then
      DM.set_next_smart_point(results, next_point)
        end
    end
    for i, results in ipairs(resultgroups) do
        DM.cache_result(results[1], "Result_Pool")
    end
end

SmartFinish = function()
    models = DM.get_model_template_from_cache("Result_Pool")
    if models == nil then
        return
    end

    gauges = DM.check_invalid_gauge(orig_gauges)

    masktemplate = DM.get_masktemplate(models)
    tcctemplate = DM.get_tcc(models)
    DM.align_smart_parameters(masktemplate, tcctemplate)
    rsttemplate  = DM.get_resist(models)
    tccs = DM.compute_tcc(tcctemplate, conds, masktemplate)

    cd = {}
    wcd = {}
    aicd = {}
    ails = {}
    adicd = {}
    semerrors = {}

    for i, gauge in pairs(gauges) do
        DM.compute_mask_image(gauge, litholayer, masktemplate)
        if (flareinput ~= nil) then
            DM.compute_aerial_image(gauge, litholayer, tccs, masktemplate, FMAP_file)
        else
            DM.compute_aerial_image(gauge, litholayer, tccs, masktemplate)
        end
    end

    ct = DM.compute_ct(gauges, rsttemplate)

    for i,sem in pairs(sems) do
        DM.load_sem_image(sem)
        DM.compute_mask_image(sem, litholayer, masktemplate)
        if (flareinput ~= nil) then
            DM.compute_aerial_image(sem, litholayer, tccs, masktemplate, FMAP_file)
        else
            DM.compute_aerial_image(sem, litholayer, tccs, masktemplate)
        end
        DM.align_sem(sem, rsttemplate)
    end

    if (ct == 0) then
        ct = DM.compute_ct(sems, rsttemplate)
    end

    gauge_signals = {{},{},{},{},{}}
    for j, gauge in ipairs(gauges) do
        DM.load_density(gauge, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(gauge, rsttemplate)

        for m = 1, table.getn(gauge_signals) do
            if (m ~= table.getn(gauge_signals)) then
                for k, v in ipairs(signal[m]) do
                    table.insert(gauge_signals[m], v)
                end
            else
                table.insert(gauge_signals[m], signal[m])
            end
        end
     end

    sem_signals = {{},{},{},{},{}}
    for j,sem in ipairs(sems) do
        DM.load_density(sem, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(sem, rsttemplate)
        for m = 1,table.getn(sem_signals)   do
            for k, v in ipairs(signal[m]) do
                table.insert(sem_signals[m], v)
            end
        end
    end

    rst = DM.search_resist_parms(gauge_signals, rsttemplate, gauges, sem_signals, sems)

    for i, gauge in ipairs(gauges) do
        gaugename = DM.get_gauge_attribute(gauge, "name")
        cd[gaugename] = DM.compute_cd(gauge, rst)
        wcd[gaugename] = DM.get_gauge_attribute(gauge, "wafer_cd")
        aicd[gaugename] = DM.compute_ai_cd(gauge, ct)
        ails[gaugename] = DM.compute_ails(gauge, cd[gaugename])
    end
    errors = DM.compute_error(cd, wcd)

    for i,sem in pairs(sems) do
        semname = DM.get_sem_attribute(sem, "name")
        semerrors[semname] = DM.compute_sem_error(sem, rst)
    end
    if (flareinput ~= nil) then
        models = DM.create_fem_model(tccs, masktemplate, rst, flareinput.f_param.flare)
    else
        models = DM.create_fem_model(tccs, masktemplate, rst)
    end

    DM.add_fem_result(models, errors, semerrors)
    DM.add_fem_result(aicd, "ai_cd")
    DM.add_fem_result(ails, "ils")
end

---------------------------------------------------------
--           Resist Simplex Search Functions           --
---------------------------------------------------------
nLinSolvFail = 0
linSolvSuccess = 0

SIMPLEX_SEARCH = function(gauges, sems, rst)
    error0 = 0
    error = 0

    DM.simplex_set_env("TARGET_FUNC_ADAPTER", gauges, sems, rst)

    startpoints = DM.simplex_get_seed_points()
    rst0 = DM.clone_resist(rst)
    for i, point in ipairs(startpoints) do
        iteration = 0
        converged = false
        DM.simplex_init_point(point)
        nLinSolvFail = 0
        while (iteration < MAXSIMPLEXITERATION and converged==false and nLinSolvFail < 10) do
            linSolvSuccess = 0
            DM.simplex_compute_next_point()
            if linSolvSuccess == 0 then
              nLinSolvFail = nLinSolvFail + 1
            else
              nLinSolvFail = 0
            end
            converged = DM.simplex_check_convergence()
            iteration = iteration + 1
        end
        error, point = DM.simplex_get_result()
        if ((error0 > error) or (i == 1)) then
            error0 = error
            point0 = point
        end
    end

    DM.simplex_load_parameters(rst0, point0)
    return rst0
end

TARGET_FUNC_ADAPTER = function(gauges, sems, rsttemplate)
    gauge_signals = {{},{},{},{},{}}
    for j, gauge in ipairs(gauges) do
        DM.load_density(gauge, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(gauge, rsttemplate)
        for m = 1, table.getn(gauge_signals) do
            if (m ~= table.getn(gauge_signals)) then
                for k, v in ipairs(signal[m]) do
                    table.insert(gauge_signals[m], v)
                end
            else
                table.insert(gauge_signals[m], signal[m])
            end
        end
    end

    sem_signals = {{},{},{},{},{}}
    for j,sem in ipairs(sems) do
        DM.load_density(sem, rsttemplate, litholayer, DENSITYTYPE)
        signal = DM.get_edge_signals(sem, rsttemplate)
        n = table.getn(sem_signals)
        for m = 1,table.getn(sem_signals)   do
            for k, v in ipairs(signal[m]) do
                table.insert(sem_signals[m], v)
            end
        end
    end

    local rst, localLinSolvSuccess = DM.search_resist_parms(gauge_signals, rsttemplate, gauges, sem_signals, sems)
    if localLinSolvSuccess ~= 0 then
      linSolvSuccess = 1
    end

    for i, gauge in ipairs(gauges) do
        gaugename = DM.get_gauge_attribute(gauge, "name")
        cd[gaugename] = DM.compute_cd(gauge, rst)
        wcd[gaugename] = DM.get_gauge_attribute(gauge, "wafer_cd")
    end

    for i,sem in pairs(sems) do
        semname = DM.get_sem_attribute(sem, "name")
        semerrors[semname] = DM.compute_sem_error(sem, rst)
    end

    rms = DM.compute_cost_function(cd, wcd, semerrors)
    return rms
end

CALC_SPEC_ERROR = function(gauges, cd, wcd)
    spec_err = {}
    displayresult = {}
    totalweight = 0
    inspecweight = 0
    for i, gauge in ipairs(gauges) do
        gaugename = DM.get_gauge_attribute(gauge, "name")
        range_min = DM.get_gauge_attribute(gauge, "range_min")
        range_max = DM.get_gauge_attribute(gauge, "range_max")
        if range_min ~= "" and range_max ~= "" then
            if range_min > range_max then
                DM.abort_job("Gauge"..gaugename..": range_min > range_max")
            end

            if math.abs(range_min) < 1e-6 and math.abs(range_max) < 1e-6 then
                spec_err[gaugename] = 0
            else
                if cd[gaugename] > wcd[gaugename] + range_max then
                    spec_err[gaugename] = cd[gaugename] - (wcd[gaugename] + range_max)
                elseif cd[gaugename] < wcd[gaugename] + range_min then
                    spec_err[gaugename] = wcd[gaugename] + range_min - cd[gaugename]
                else
                    spec_err[gaugename] = 0
                end
                weight = DM.get_gauge_attribute(gauge, "weight")
                totalweight = totalweight + weight
                if spec_err[gaugename] == 0 then
                    inspecweight = inspecweight + weight
                end
            end
        end
    end

    if totalweight ~= 0 then
        DM.add_fem_result(spec_err, "spec_error", "Spec_error")
        displayresult = {["(In Spec Ratio)"] = inspecweight / totalweight}
    end

    return displayresult
end
