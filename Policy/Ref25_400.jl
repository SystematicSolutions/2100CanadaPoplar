#
# Ref25_400.jl - Ref25 plus CP 170 policies
#

module Policy

import ...EnergyModel: DB

include("SetAsReferenceCase.jl")
include("PatchFsPOCXTrans.jl")
include("Ammonia_Exports.jl")
include("Hydrogen_Prices.jl")

#
# Biofuels and Solar
#
include("KPIA_Biofuels_Prov.jl")
include("LCFS_BC.jl")

#
# Residential and Commercial Building Code
#
include("Com_BldgStdPolicy.jl")
include("Res_BldgStdPolicy.jl")

#
# QC Process Retrofit
#
include("QC_EcoPerf_Com.jl")

#
# Residential and Commercial Equipment Standards
#
include("StdEq_Com_U19.jl")
include("StdEq_Res_U19.jl")

#
# Residential and Commercial LCEF
#
include("LCEFL_Res.jl")
include("LCEFC_HFC_Com.jl")
include("Res_PeakSavings.jl")
include("Com_PeakSavings.jl")

#
# Residential and Commercial Lighting Retrofits (Mercury)
#
include("Hg_Com.jl")
include("Hg_Res.jl")

#
# Residential Market Shares
#
include("Res_MS_Electric_NL.jl")
include("Res_MS_Biomass_NT.jl")
include("Res_MS_HeatPump_BC.jl")
include("Res_MS_HeatPump_NRCAN.jl")
include("Res_MS_NewElectric_CA.jl")

#
# Residential Conversions
#
include("Res_Conv_Initialize.jl")
include("Res_Conv_All.jl")
include("Res_Conv_HEES_BC.jl")

#
# Commercial Market Shares
#
include("Com_MS_Electric_NL.jl")
include("Com_MS_Biomass_NT.jl")
include("Com_MS_HeatPump_BC.jl")
include("Com_MS_LCEFC.jl")
include("Com_MS_NewElectric_CA.jl")

#
# Commercial Conversions
#
include("Com_Conv_Initialize.jl")
include("Com_Conv_All.jl")
include("Com_Conv_HEES_BC.jl")

#
# NRCan RDD Projects
#
include("ResCom_EIP.jl")

#
# Industrial
#
include("Ind_Biomass_QC.jl")
include("Ind_LCEF_Dev.jl")
include("Ind_LCEF_Leader.jl")
include("Ind_LCEF_Pro.jl")
include("Ind_EnM.jl")
include("Ind_EcoPerformQC.jl")
include("AdjustCAC_Steel_2024.jl")
include("Ind_PeakSavings.jl")
include("Ind_NG.jl")
include("Ind_CleanBC_Cmnt.jl")
include("Ind_CleanBC_PP.jl")
include("Ind_CleanBC_SourGas.jl")
include("Ind_CleanBC_UnConv.jl")
#include("Ind_AB_Cement.jl")
include("Ind_AB_PP.jl")
include("Ind_EIP_Cement.jl")
include("Ind_RioBlue.jl")
include("Ind_RioBlue_NG.jl")
include("Ind_NL_Adjust.jl")
include("Ind_NLOC_Eff.jl")
include("Ind_NLOC_Pro.jl")
include("Ind_Elec_ON.jl")
include("Ind_Elec_MB.jl")
include("Ind_Elec_NB.jl")

#
# Industrial Market Shares
#
include("Ind_MS_Elec_PeaceRiverBC.jl")
include("Ind_MS_IronSteel.jl")
include("Ind_MS_LCEF_EIP.jl")
include("Ind_MS_OCNL.jl")
include("Ind_MS_Biomass_Exo.jl")

#
# Industrial Conversions (needs testing)
#
include("Ind_Conv_Initialize.jl")
include("Ind_Conv_BC_Elec.jl")

#
# Industrial Fungible Demands
#
# include("Ind_Fungible_Initialize.jl")
include("Ind_H2_DemandsAP.jl")
include("Ind_H2_FeedstocksAP.jl")

#
# Hydrogen Supply
#
include("H2_Supply.jl")
include("Hydrogen_ITC.jl")

#
# Transportation
#
include("HDV2.jl")
include("TransElectric_Parameters.jl")
include("LDV2.jl")
include("Trans_Vol_Rail.jl")
include("Trans_Vol_Planes.jl")
include("QCPETMAF.jl")
include("GreenFreightProgram.jl")
include("Trans_OffRoad_Electrify.jl")

#
# Transportation Market Shares
#
include("Trans_MS_LDV_Electric.jl")
include("Trans_MS_Bus_Train.jl")
include("Trans_MS_PREGTI_QC.jl")
include("Trans_MS_Freight_Modal_Shares.jl")
include("Trans_MS_HDV_Electric_BC.jl")
include("Trans_MS_iMHZEV.jl")
include("Trans_MS_LDV_CA.jl")
include("Trans_MS_HDV_CA.jl")
include("Trans_MS_Train_CA.jl")

#
# Multiple Sectors
# Any policies which change xMMSF, xDmFrac, or xFsFrac should be
# split by sector and moved up in batch file - Jeff Amlin 2/4/25
#
include("OG_MRA.jl")
include("OG_Venting.jl")
# include("OG_OtherFugitives_IEACurves_EMR.jl")
# include("OG_Venting_IEACurves_EMR.jl")
include("HFCS.jl")
include("Eff_MB_Act.jl")
include("Waste_diversion.jl")
# include("Waste_LFG.jl")
include("Res_CGHG.jl")
include("Res_CHMC_Loan.jl")
include("EIP_CCS_2.jl")
include("GHG_CCSCurves.jl")
include("CCS_ITC.jl")
include("CCS_Heidelberg_AB.jl")
include("RNG_Standard_BC.jl")
include("RNG_Standard_QC.jl")

#
# CAC
#
include("CAC_FreightStandards.jl")
include("CAC_PassStandards.jl")
include("CAC_NL_AirControlReg.jl")
include("CAC_NS_AirQualityReg.jl")
include("CAC_BLIERS.jl")
include("CAC_CCME_AcidRain.jl")
include("ParasiticLoss.jl")
include("CAC_OffRoad.jl")
include("CAC_CleanAir_QC.jl")
include("CAC_ProvRecipReg.jl")
include("CAC_ExogenousCogen_LNG.jl")
include("CAC_MSAPR.jl")
include("CAC_Locomotive.jl")
include("CAC_VOC_PetroleumSectors.jl")
include("CAC_VOC_Products.jl")
include("CAC_ON_SOXPetroProd.jl")
include("CAC_ON_SOX_Nickel_Smelting_Refining.jl")
include("CAC_Hg_Products.jl")
include("AdjustCAC_NL_Elec.jl")
include("AdjustCAC_NB_Elec.jl")
include("CAC_ON_CarbonBlack.jl")
include("CAC_VOCII_Reg.jl")
include("AdjustCAC_SK_Cogen.jl")
include("AdjustCAC_BC_Mercury.jl")

#
# Efficiency Improvements
#
# include("GHGNonEnergyPolicy.jl")
include("AdjustEnergyIntensity_Petroleum.jl")

#
# Ontario Conservation Measures
#
include("Retro_Device_Com_NG.jl")
include("Retro_Device_Res_NG.jl")
include("Retro_Process_Com_NG.jl")
include("Retro_Process_Com_Elec.jl")
include("Retro_Process_Res_NG.jl")
include("Retro_Process_Res_Elec.jl")
include("Retro_Process_Com_Elec_MB.jl")
include("Retro_Process_Com_Elec_NB.jl")
include("Retro_Process_Res_Elec_MB.jl")
include("Retro_Process_Res_Elec_NB.jl")
include("Com_DataCenter.jl")

#
# Non-CO2 Reduction Curves
#
include("GHG_Ind_ProcessReductionCurves.jl")
include("HFC_ReductionCurves_ON_QC.jl")

#
#
# ************************
#
# Exogenous Clean Fuel Standard
#
#  # Call PrmFile PCF_Ind_DmFrac_PetroCoke.txp
#  # Call PrmFile PCF_Ind_DmFrac_HFO.txp
# Call PrmFile TR_BF2.txp
# Call PrmFile TR-Biofuels-PK3.txp
# Call PrmFile OffRoad_BF4_noRNG.txp
# Call PrmFile RBuild_BF3_noRNG.txp
# Call PrmFile CBuild_BF3_noRNG.txp
# Call PrmFile Ind_BF4_noRNG.txp
# Call PrmFile Adjust_Biod_Max_CFR.txp
#  # Call PrmFile CCS_CFR_Exo_LOM.txp
#  # Call PrmFile CCS_CFR_Exo_OSU.txp
# Call PrmFile CCS_CFR_Exo_Petro.txp
#
# Endogenous Clean Fuel Standard
#
include("CFS_LiquidEVCredit.jl")
include("CFS_LiquidNGCredit.jl")
include("CFS_LiquidMarket_CN.jl")
include("CFS_LiquidPrice.jl")

#
# California Policies (except market share and conversion policies)
#
include("RenewableLiquidsMaximum_CA.jl")
include("RNG_H2_Pipeline_CA.jl")
include("Ind_Food_CA.jl")
include("Ind_Construction_CA.jl")
include("Ind_OtherManufacturing_CA.jl")
include("Ind_Chemicals_CA.jl")
include("Ind_OnFarm_CA.jl")
include("Ind_Process_Cement_CA.jl")
include("Ag_Methane_Reduction_CA.jl")
include("Trans_PEStdP_CA.jl")
include("Trans_DEStdP_CA.jl")
include("Trans_MarineOffRoad_CA.jl")
include("Trans_Plane_CA.jl")
include("Trans_OGV_CA.jl")
include("Trans_BiofuelEmissions_CA.jl")
include("Trans_MS_Biofuels_CA.jl")
include("OGProduction_CA.jl")
include("Petroleum_CA.jl")
include("FossilGeneration_CA.jl")
include("Electric_ImportEmissions_CA.jl")
include("DAC_Exogenous_CA.jl")
include("Fertilizer_Reduction.jl")
include("Ag_ACT_CO2_reduction.jl")

#
#  Electric Generation
#

#
# Pre-processing: General parameters (Not-policy)
#
include("Electric_DeliveryCharge_Switch.jl")
include("Electric_Endogenous_Capacity.jl")
# include("Electric_OutageRates.jl")    (changes are made in vData)
include("Electric_BTF_Units.jl")
include("Electric_DesignHours.jl")

#
# Policy: National Coal Electric Performance Standard
#
include("Electric_Fed_Coal_Retire.jl")
include("Electric_Fed_Coal_Amendment.jl")

#
# Policy: NRCan Electricity Policies
#
include("Electric_NRCan_EmergingRenewables.jl")
include("Electric_NRCan_SmallCommunities.jl")
include("Electric_NRCan_SmartGrid_Energy.jl")
include("Electric_NRCan_SmartGrid_Peak.jl")

#
# Policy: Electricity ITC's
# (Budget 2022 / FES 2022 / Budget 2023) and SREPs (NextGrid)
#
include("Electric_ITCs.jl")
# include("Electricity_SREPS.jl")

#
# Policy: BC Electric Offsets Policy
# Comment: OffSw is used in /Enginne/EPollution.jl
# if it is truly a policy, it seems missing in the official policy list (Sharepoint)
#
include("Electric_BC_Offsets.jl")

#
# Policy: Nova Scotia Electric Performance Standard
#
include("Electric_NS_Renewable.jl")
include("Electric_NS_GHGLimit.jl")

#
# Policy: Clean Electricity Regulations
include("Electric_CER_Endogenous_Units.jl")
include("Electric_CER_Exogenous_Units.jl")
include("Electric_CER_Exogenous_PCFMax.jl")

#
# Post-Processing: Patches (Not-Policy)
#
include("Electric_Patch.jl")
include("Electric_SK_Coal_Cost.jl")
include("Electric_Patch_Exports.jl")
include("Electric_NS_HydroPurchases.jl")


#
# Carbon Tax with OBA
#
include("CarbonTax_OBA_ON.jl")
include("CarbonTax_OBA_NB.jl")
include("CarbonTax_OBA_SK.jl")
include("CarbonTax_OBA_NL.jl")
include("CarbonTax_OBA_AB.jl")
include("CarbonTax_OBA_NS.jl")
include("CarbonTax_OBA_BC.jl")
include("CarbonTax_OBA_Fed_170.jl")
include("CarbonTaxRemoval.jl")
include("CarbonTax_All_400.jl")

function IncorporatePolicies()
  @info "IncorporatePolicies - Ref25_400"

  SetAsReferenceCase.PolicyControl(DB)
  PatchFsPOCXTrans.PolicyControl(DB)
  Ammonia_Exports.PolicyControl(DB)
  Hydrogen_Prices.PolicyControl(DB)



  #
  # Biofuels and Solar
  #
  KPIA_Biofuels_Prov.PolicyControl(DB)
  LCFS_BC.PolicyControl(DB)

  #
  # Residential and Commercial Building Code
  #
  Com_BldgStdPolicy.PolicyControl(DB)
  Res_BldgStdPolicy.PolicyControl(DB)

  #
  # QC Process Retrofit
  #
  QC_EcoPerf_Com.PolicyControl(DB)

  #
  # Residential and Commercial Equipment Standards
  #
  StdEq_Com_U19.PolicyControl(DB)
  StdEq_Res_U19.PolicyControl(DB)

  #
  # Residential and Commercial LCEF
  #
  LCEFL_Res.PolicyControl(DB)
  LCEFC_HFC_Com.PolicyControl(DB)
  Res_PeakSavings.PolicyControl(DB)
  Com_PeakSavings.PolicyControl(DB)

  #
  # Residential and Commercial Lighting Retrofits (Mercury)
  #
  Hg_Com.PolicyControl(DB)
  Hg_Res.PolicyControl(DB)

  #
  # Residential Market Shares
  #
  Res_MS_Electric_NL.PolicyControl(DB)
  Res_MS_Biomass_NT.PolicyControl(DB)
  Res_MS_HeatPump_BC.PolicyControl(DB)
  Res_MS_HeatPump_NRCAN.PolicyControl(DB)
  Res_MS_NewElectric_CA.PolicyControl(DB)
  #
  # Residential Conversions
  #
  Res_Conv_Initialize.PolicyControl(DB)
  Res_Conv_All.PolicyControl(DB)
  Res_Conv_HEES_BC.PolicyControl(DB)

  #
  # Commercial Market Shares
  #
  Com_MS_Electric_NL.PolicyControl(DB)
  Com_MS_Biomass_NT.PolicyControl(DB)
  Com_MS_HeatPump_BC.PolicyControl(DB)
  Com_MS_LCEFC.PolicyControl(DB)
  Com_MS_NewElectric_CA.PolicyControl(DB)
  #
  # Commercial Conversions
  #
  Com_Conv_Initialize.PolicyControl(DB)
  Com_Conv_All.PolicyControl(DB)
  Com_Conv_HEES_BC.PolicyControl(DB)  
  
  #
  # NRCan RDD Projects
  #
  ResCom_EIP.PolicyControl(DB)

  #
  # Industrial
  #
  Ind_Biomass_QC.PolicyControl(DB)
  Ind_LCEF_Dev.PolicyControl(DB)
  Ind_LCEF_Leader.PolicyControl(DB)
  Ind_LCEF_Pro.PolicyControl(DB)
  Ind_EnM.PolicyControl(DB)
  Ind_EcoPerformQC.PolicyControl(DB)
  AdjustCAC_Steel_2024.PolicyControl(DB)
  Ind_PeakSavings.PolicyControl(DB)
  # Ind_NRC_EIP.PolicyControl(DB)
  # Ind_Elec.PolicyControl(DB)
  Ind_NG.PolicyControl(DB)
  Ind_CleanBC_Cmnt.PolicyControl(DB)
  Ind_CleanBC_PP.PolicyControl(DB)
  Ind_CleanBC_SourGas.PolicyControl(DB)
  Ind_CleanBC_UnConv.PolicyControl(DB)
  # Ind_AB_Cement.PolicyControl(DB)
  Ind_AB_PP.PolicyControl(DB)
  Ind_EIP_Cement.PolicyControl(DB)
  Ind_RioBlue.PolicyControl(DB)
  Ind_RioBlue_NG.PolicyControl(DB)
  Ind_NL_Adjust.PolicyControl(DB)
  Ind_NLOC_Eff.PolicyControl(DB)
  Ind_NLOC_Pro.PolicyControl(DB)
  Ind_Elec_ON.PolicyControl(DB)
  Ind_Elec_MB.PolicyControl(DB)
  Ind_Elec_NB.PolicyControl(DB)

  #
  # Industrial Market Shares
  #
  Ind_MS_Elec_PeaceRiverBC.PolicyControl(DB)
  Ind_MS_IronSteel.PolicyControl(DB)
  Ind_MS_LCEF_EIP.PolicyControl(DB)
  Ind_MS_OCNL.PolicyControl(DB)
  Ind_MS_Biomass_Exo.PolicyControl(DB)

  #
  # Industrial Conversions (needs testing)
  #
  Ind_Conv_Initialize.PolicyControl(DB)
  Ind_Conv_BC_Elec.PolicyControl(DB)

  #
  # Industrial Fungible Demands
  #
  Ind_H2_DemandsAP.PolicyControl(DB)
  Ind_H2_FeedstocksAP.PolicyControl(DB)

  #
  # Hydrogen Supply
  #
  H2_Supply.PolicyControl(DB)
  Hydrogen_ITC.PolicyControl(DB)

  #
  # Transportation
  #
  HDV2.PolicyControl(DB)
  TransElectric_Parameters.PolicyControl(DB)
  LDV2.PolicyControl(DB)
  Trans_Vol_Rail.PolicyControl(DB)
  Trans_Vol_Planes.PolicyControl(DB)
  QCPETMAF.PolicyControl(DB)
  GreenFreightProgram.PolicyControl(DB)
  Trans_OffRoad_Electrify.PolicyControl(DB)
  #
  # Transportation Market Shares
  #
  Trans_MS_LDV_Electric.PolicyControl(DB)
  Trans_MS_Bus_Train.PolicyControl(DB)
  Trans_MS_PREGTI_QC.PolicyControl(DB)
  Trans_MS_Freight_Modal_Shares.PolicyControl(DB)
  Trans_MS_HDV_Electric_BC.PolicyControl(DB)
  Trans_MS_iMHZEV.PolicyControl(DB)
  Trans_MS_LDV_CA.PolicyControl(DB)
  Trans_MS_HDV_CA.PolicyControl(DB)
  Trans_MS_Train_CA.PolicyControl(DB)

  #
  # Multiple Sectors
  # Any policies which change xMMSF, xDmFrac, or xFsFrac should be
  # split by sector and moved up in batch file - Jeff Amlin 2/4/25
  #
  OG_MRA.PolicyControl(DB)
  OG_Venting.PolicyControl(DB)
  # OG_OtherFugitives_IEACurves_EMR.PolicyControl(DB)
  # OG_Venting_IEACurves_EMR.PolicyControl(DB)
  HFCS.PolicyControl(DB)
  Eff_MB_Act.PolicyControl(DB)
  Waste_diversion.PolicyControl(DB)
  # Waste_LFG.PolicyControl(DB)
  Res_CGHG.PolicyControl(DB)
  Res_CHMC_Loan.PolicyControl(DB)
  EIP_CCS_2.PolicyControl(DB)
  GHG_CCSCurves.PolicyControl(DB)
  CCS_ITC.PolicyControl(DB)
  CCS_Heidelberg_AB.PolicyControl(DB)

  #
  # RNG_Standard.PolicyControl(DB)
  #
  RNG_Standard_BC.PolicyControl(DB)
  RNG_Standard_QC.PolicyControl(DB)

  #
  # CAC
  #
  CAC_FreightStandards.PolicyControl(DB)
  CAC_PassStandards.PolicyControl(DB)
  CAC_NL_AirControlReg.PolicyControl(DB)
  CAC_NS_AirQualityReg.PolicyControl(DB)
  CAC_BLIERS.PolicyControl(DB)
  CAC_CCME_AcidRain.PolicyControl(DB)
  ParasiticLoss.PolicyControl(DB)
  CAC_OffRoad.PolicyControl(DB)
  CAC_CleanAir_QC.PolicyControl(DB)
  CAC_ProvRecipReg.PolicyControl(DB)
  CAC_ExogenousCogen_LNG.PolicyControl(DB)
  CAC_MSAPR.PolicyControl(DB)
  CAC_Locomotive.PolicyControl(DB)
  CAC_VOC_PetroleumSectors.PolicyControl(DB)
  CAC_VOC_Products.PolicyControl(DB)
  CAC_ON_SOXPetroProd.PolicyControl(DB)
  CAC_ON_SOX_Nickel_Smelting_Refining.PolicyControl(DB)
  CAC_ON_CarbonBlack.PolicyControl(DB)
  CAC_Hg_Products.PolicyControl(DB)
  AdjustCAC_NL_Elec.PolicyControl(DB)
  AdjustCAC_NB_Elec.PolicyControl(DB)
  CAC_VOCII_Reg.PolicyControl(DB)
  AdjustCAC_SK_Cogen.PolicyControl(DB)
  AdjustCAC_BC_Mercury.PolicyControl(DB)

  #
  # Efficiency Improvements
  #
  AdjustEnergyIntensity_Petroleum.PolicyControl(DB)

  #
  # Ontario Conservation Measures
  #
  Retro_Device_Com_NG.PolicyControl(DB)
  Retro_Device_Res_NG.PolicyControl(DB)
  Retro_Process_Com_NG.PolicyControl(DB)
  Retro_Process_Com_Elec.PolicyControl(DB)
  Retro_Process_Res_NG.PolicyControl(DB)
  Retro_Process_Res_Elec.PolicyControl(DB)
  Retro_Process_Com_Elec_MB.PolicyControl(DB)
  Retro_Process_Com_Elec_NB.PolicyControl(DB)
  Retro_Process_Res_Elec_MB.PolicyControl(DB)
  Retro_Process_Res_Elec_NB.PolicyControl(DB)
  Com_DataCenter.PolicyControl(DB)

  #
  # Non-CO2 Reduction Curves
  #
  GHG_Ind_ProcessReductionCurves.PolicyControl(DB)
  HFC_ReductionCurves_ON_QC.PolicyControl(DB)

  #
  # ************************
  #
  # Exogenous Clean Fuel Standard
  #
  #  # Call PrmFile PCF_Ind_DmFrac_PetroCoke.txp
  #  # Call PrmFile PCF_Ind_DmFrac_HFO.txp
  # Call PrmFile TR_BF2.txp
  # Call PrmFile TR-Biofuels-PK3.txp
  # Call PrmFile OffRoad_BF4_noRNG.txp
  # Call PrmFile RBuild_BF3_noRNG.txp
  # Call PrmFile CBuild_BF3_noRNG.txp
  # Call PrmFile Ind_BF4_noRNG.txp
  # Call PrmFile Adjust_Biod_Max_CFR.txp
  #   # Call PrmFile CCS_CFR_Exo_LOM.txp
  #   # Call PrmFile CCS_CFR_Exo_OSU.txp
  # Call PrmFile CCS_CFR_Exo_Petro.txp

  #
  # Endogenous Clean Fuel Standard
  #
  CFS_LiquidEVCredit.PolicyControl(DB)
  CFS_LiquidNGCredit.PolicyControl(DB)
  CFS_LiquidMarket_CN.PolicyControl(DB)
  CFS_LiquidPrice.PolicyControl(DB)

  #
  # California Policies (except market share and conversion policies)
  #
  RenewableLiquidsMaximum_CA.PolicyControl(DB)
  RNG_H2_Pipeline_CA.PolicyControl(DB)
  Ind_Food_CA.PolicyControl(DB)
  Ind_Construction_CA.PolicyControl(DB)
  Ind_OtherManufacturing_CA.PolicyControl(DB)
  Ind_Chemicals_CA.PolicyControl(DB)
  Ind_OnFarm_CA.PolicyControl(DB)
  Ind_Process_Cement_CA.PolicyControl(DB)
  Ag_Methane_Reduction_CA.PolicyControl(DB)
  Trans_PEStdP_CA.PolicyControl(DB)
  Trans_DEStdP_CA.PolicyControl(DB)
  Trans_MarineOffRoad_CA.PolicyControl(DB)
  Trans_Plane_CA.PolicyControl(DB)
  Trans_OGV_CA.PolicyControl(DB)
  Trans_BiofuelEmissions_CA.PolicyControl(DB)
  Trans_MS_Biofuels_CA.PolicyControl(DB)
  OGProduction_CA.PolicyControl(DB)
  Petroleum_CA.PolicyControl(DB)
  FossilGeneration_CA.PolicyControl(DB)
  Electric_ImportEmissions_CA.PolicyControl(DB)
  DAC_Exogenous_CA.PolicyControl(DB)

  Fertilizer_Reduction.PolicyControl(DB)
  Ag_ACT_CO2_reduction.PolicyControl(DB)

  #
  #  Electricity Generation
  #
  
  #
  # Pre-processing: General parameters (Not-policy)
  #
  Electric_DeliveryCharge_Switch.PolicyControl(DB)
  Electric_Endogenous_Capacity.PolicyControl(DB)
  # Electric_OutageRates.PolicyControl(DB)   (changes are made in vData)
  Electric_BTF_Units.PolicyControl(DB)
  Electric_DesignHours.PolicyControl(DB)
  
  #
  # Policies
  #
  Electric_Fed_Coal_Retire.PolicyControl(DB)
  Electric_Fed_Coal_Amendment.PolicyControl(DB)
  Electric_NRCan_EmergingRenewables.PolicyControl(DB)
  Electric_NRCan_SmallCommunities.PolicyControl(DB)
  Electric_NRCan_SmartGrid_Energy.PolicyControl(DB)
  Electric_NRCan_SmartGrid_Peak.PolicyControl(DB)
  Electric_ITCs.PolicyControl(DB)
  # Electricity_SREPS.PolicyControl(DB)
  Electric_BC_Offsets.PolicyControl(DB)
  Electric_NS_Renewable.PolicyControl(DB)
  Electric_NS_GHGLimit.PolicyControl(DB)
  Electric_CER_Endogenous_Units.PolicyControl(DB)
  Electric_CER_Exogenous_Units.PolicyControl(DB)
  Electric_CER_Exogenous_PCFMax.PolicyControl(DB)
  
  #
  # Post-processing: Patches (Not-policy)  
  #
  Electric_Patch.PolicyControl(DB)
  Electric_SK_Coal_Cost.PolicyControl(DB)
  Electric_Patch_Exports.PolicyControl(DB)
  Electric_NS_HydroPurchases.PolicyControl(DB)

  #
  # Carbon Tax with OBA
  #
  CarbonTaxRemoval.PolicyControl(DB)
  CarbonTax_All_400.PolicyControl(DB)

end

end

