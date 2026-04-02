#
# Ref25A.jl - Execute non-integrated Additional Measures Case
#

module Policy

import ...EnergyModel: DB

include("PatchFsPOCXTrans.jl")
include("SetAsReferenceCase.jl")
include("AdjustNLOtherChemicals_A_TOM.jl")
include("Ammonia_Exports.jl")
include("Hydrogen_Prices.jl")

#
# Biofuels and Solar
#
include("KPIA_Biofuels_Prov_A.jl")
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
include("Res_MS_CGBS_OilProhibition.jl")
include("Res_MS_HEES_BC_GasProhibition.jl")
include("Res_MS_Incentive_Opt1.jl")
include("Res_MS_NewElectric_CA.jl")

#
# Residential Conversions
#
include("Res_Conv_Initialize.jl")
include("Res_Conv_All.jl")
include("Res_Conv_HEES_BC.jl")
include("Res_Conv_CGBS_Option1.jl")

#
# Commercial Market Shares
#
include("Com_MS_Electric_NL.jl")
include("Com_MS_Biomass_NT.jl")
include("Com_MS_HeatPump_BC.jl")
include("Com_MS_LCEFC.jl")
include("Com_MS_CGBS_OilProhibition.jl")
include("Com_MS_HEES_BC_GasProhibition.jl")
include("Com_MS_Incentive_Opt1.jl")
include("Com_MS_NewElectric_CA.jl")

#
# Commercial Conversions
#
include("Com_Conv_Initialize.jl")
include("Com_Conv_All.jl")
include("Com_Conv_HEES_BC.jl")
include("Com_Conv_CGBS_Option1.jl")

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
include("Ind_Elec.jl")
include("Ind_NG.jl")
include("Ind_CleanBC_Cmnt.jl")
include("Ind_CleanBC_PP.jl")
include("Ind_CleanBC_SourGas.jl")
include("Ind_CleanBC_UnConv.jl")
include("Ind_AB_Cement.jl")
include("Ind_AB_PP.jl")
include("Ind_EIP_Cement.jl")
# include("Ind_H2IronSteel.jl")
include("Ind_RioBlue.jl")
include("Ind_RioBlue_NG.jl")
include("Ind_MineNL.jl")
# include("Ind_IronOre_QC.jl")
include("Ind_Elec_ON.jl")
include("Ind_Elec_MB.jl")
include("Ind_Elec_NB.jl")

#
# Industrial Market Shares
#
include("Ind_MS_Elec_PeaceRiverBC.jl")
include("Ind_MS_IronSteel_RefA.jl")
include("Ind_MS_LCEF_EIP.jl")
# include("Ind_MS_P30.jl")
include("Ind_MS_Biomass_Exo.jl")

#
# Industrial Conversions (needs testing)
#
include("Ind_Conv_Initialize.jl")
include("Ind_Conv_BC_Elec.jl")
# include("Ind_Conv_All.jl")

#
# Industrial Fungible Demands
#
# include("HydrogenResCom.jl")
include("Ind_H2_DemandsAP_RefA.jl")
include("Ind_H2_FeedstocksAP_RefA.jl")

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
include("LDV2_A.jl")
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
include("Trans_MS_Electric_Bus_A.jl")
include("Trans_MS_PREGTI_QC.jl")
include("Trans_MS_Freight_Modal_Shares.jl")
include("Trans_MS_iMHZEV.jl")
include("Trans_MS_FuelCell.jl")
include("Trans_MS_Marine.jl")
include("Trans_MS_LDV_CA.jl")
include("Trans_MS_HDV_CA.jl")
include("Trans_MS_Train_CA.jl")
#
# Multiple Sectors
# Any policies which change xMMSF, xDmFrac, or xFsFrac should be
# split by sector and moved up in batch file - Jeff Amlin 2/4/25
#
include("OG_MRA_EMR.jl")
include("OG_Venting.jl")
# include("OG_OtherFugitives_IEACurves_EMR.jl")
# include("OG_Venting_IEACurves_EMR.jl")
include("HFCS.jl")
include("Eff_MB_Act.jl")
include("Waste_diversion.jl")
include("Waste_LFG.jl")
include("Res_CGHG.jl")
include("Res_CHMC_Loan.jl")
include("GHG_CCSCurves_RefA.jl")
# include("EIP_CCS_1.jl")
include("EIP_CCS_2_RefA.jl")
# include("CCS_Glacier.jl")
include("OG_CCS_Projects.jl")
# include("CCS_FedCoop_1.jl")
include("CCS_FedCoop_2.jl")
# include("CCS_Polaris.jl")
include("CCS_Polaris_2.jl")
include("CCS_HeidelbergLafarge_AB.jl")
include("CCS_Stelco_ON.jl")
include("CCS_ITC_RefA.jl")

# include("RNG_Standard.jl")
include("RNG_Standard_BC_A.jl")
include("RNG_Standard_QC.jl")

#
# CAC
#
include("CAC_FreightStandards.jl")
include("CAC_PassStandards.jl")
include("CAC_NL_AirControlReg.jl")
include("CAC_NS_AirQualityReg.jl")
include("CAC_BLIERS.jl")
include("CAC_CCME_AcidRain_A.jl")
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
include("CAC_ON_CarbonBlack.jl")
include("CAC_Hg_Products.jl")
include("AdjustCAC_NL_Elec.jl")
include("AdjustCAC_NB_Elec.jl")
include("CAC_VOCII_Reg.jl")
include("AdjustCAC_SK_Cogen.jl")
include("AdjustCAC_BC_Mercury.jl")
include("CAC_ELYSIS.jl")

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

#
# Endogenous Clean Fuel Standard
#
include("CFS_LiquidEVCredit.jl")
include("CFS_LiquidNGCredit.jl")
include("CFS_LiquidMarket_CN.jl")
include("CFS_LiquidPrice_A.jl")

#
# Additional Measures Policies
# Any policies which change xMMSF, xDmFrac, or xFsFrac should be
# split by sector and moved up in the batch file - Jeff Amlin 2/4/2

#
# Built Environment Policies
#
include("Res_BldgNZ.jl")
include("Com_BldgNZ.jl")

#
# PCF 3.0
#
# include("EndogenousElectricCapacity_2.jl")
# include("PCF_DeviceStd_Res.jl")
# include("PCF_DeviceStd_Com.jl")

# include("PCF_Retro_Com.jl")
# include("Trans_OffRoad_Electrify.jl")
# include("P30_Al_InertAnode.jl")
# include("P30_Ind_Process.jl")
# include("P30_Ind_SAGD.jl")
# include("OG_SAGD_Solvent.jl")
include("Active_Transportation.jl")
# include("CleanBC_CCS_NG.jl")
# include("LCFS_BC_A.jl")
include("Fertilizer_Reduction.jl")
include("Ag_ACT_CO2_reduction.jl")
include("OBPS_FC_Com.jl")
include("OBPS_FC_Ind.jl")
include("OBPS_FC_Manuf.jl")
include("OBPS_FC_OG.jl")
include("OBPS_FC_Agr.jl")
# include("ElecCostsRenew1.jl")
include("FixNH3PlantDemand.jl")

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

#
# Electric Generation
#

#
# Pre-processing: General parameters (Not-policy)
#
include("Electric_DeliveryCharge_Switch.jl")
include("Electric_Endogenous_Capacity.jl")
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
# Policy: Electricity ITC's (AM version)
# (Budget 2022 / FES 2022 / Budget 2023) and SREPs (NextGrid)
#
# include("Electric_ITCs.jl")
include("Electric_ITCs_AM.jl")
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
# Policy: Clean Electricity Regulations (AM version)
# (NextGrid were rerun because Ref and RefA loads were too different)
#
include("Electric_CER_Endogenous_Units.jl")
# include("Electric_CER_Exogenous_Units.jl")
include("Electric_CER_Exogenous_Units_AM.jl")
include("Electric_CER_Exogenous_PCFMax.jl")

#
# AM Policies
#
# include(Electric_AM_Capacity.jl")
include("Electric_AM_Transmission.jl")
include("Electric_AM_Transmission_Costs.jl")
include("Electric_AM_BC_Gas_Retire.jl")

#
# Post-Processing: Patches (Not-Policy)
#
# include("Electric_Patch.jl")
include("Electric_Patch_AM.jl")
include("Electric_SK_Coal_Cost.jl")
# include("Electric_Patch_Exports.jl")
include("Electric_Patch_Exports_AM.jl")
include("Electric_NS_HydroPurchases.jl")

#
# Oil and Gas Emissions Cap (OGEC)
#
#include("OGEC_Market.jl")
#include("OGEC_Prices.jl")

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


function IncorporatePolicies()
  @info "IncorporatePolicies - Ref25A"

  PatchFsPOCXTrans.PolicyControl(DB)
  SetAsReferenceCase.PolicyControl(DB)
  AdjustNLOtherChemicals_A_TOM.PolicyControl(DB)
  Ammonia_Exports.PolicyControl(DB)
  Hydrogen_Prices.PolicyControl(DB)

  #
  # Biofuels and Solar
  #
  KPIA_Biofuels_Prov_A.PolicyControl(DB)
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
  Res_MS_CGBS_OilProhibition.PolicyControl(DB)
  Res_MS_HEES_BC_GasProhibition.PolicyControl(DB)
  Res_MS_Incentive_Opt1.PolicyControl(DB)
  Res_MS_NewElectric_CA.PolicyControl(DB)

  #
  # Residential Conversions
  #
  Res_Conv_Initialize.PolicyControl(DB)
  Res_Conv_All.PolicyControl(DB)
  Res_Conv_HEES_BC.PolicyControl(DB)
  Res_Conv_CGBS_Option1.PolicyControl(DB)

  #
  # Commercial Market Shares
  #
  Com_MS_Electric_NL.PolicyControl(DB)
  Com_MS_Biomass_NT.PolicyControl(DB)
  Com_MS_HeatPump_BC.PolicyControl(DB)
  Com_MS_LCEFC.PolicyControl(DB)
  Com_MS_CGBS_OilProhibition.PolicyControl(DB)
  Com_MS_HEES_BC_GasProhibition.PolicyControl(DB)
  Com_MS_Incentive_Opt1.PolicyControl(DB)
  Com_MS_NewElectric_CA.PolicyControl(DB)

  #
  # Commercial Conversions
  #
  Com_Conv_Initialize.PolicyControl(DB)
  Com_Conv_All.PolicyControl(DB)
  Com_Conv_HEES_BC.PolicyControl(DB)  
  Com_Conv_CGBS_Option1.PolicyControl(DB)
  
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
  Ind_Elec.PolicyControl(DB)
  Ind_NG.PolicyControl(DB)
  Ind_CleanBC_Cmnt.PolicyControl(DB)
  Ind_CleanBC_PP.PolicyControl(DB)
  Ind_CleanBC_SourGas.PolicyControl(DB)
  Ind_CleanBC_UnConv.PolicyControl(DB)
  Ind_AB_Cement.PolicyControl(DB)
  Ind_AB_PP.PolicyControl(DB)
  Ind_EIP_Cement.PolicyControl(DB)
  # Ind_H2IronSteel.PolicyControl(DB)
  Ind_RioBlue.PolicyControl(DB)
  Ind_RioBlue_NG.PolicyControl(DB)
  Ind_MineNL.PolicyControl(DB)
  # Ind_IronOre_QC.PolicyControl(DB)
  Ind_Elec_ON.PolicyControl(DB)
  Ind_Elec_MB.PolicyControl(DB)
  Ind_Elec_NB.PolicyControl(DB)

  #
  # Industrial Market Shares
  #
  Ind_MS_Elec_PeaceRiverBC.PolicyControl(DB)
  Ind_MS_IronSteel_RefA.PolicyControl(DB)
  Ind_MS_LCEF_EIP.PolicyControl(DB)
  # Ind_MS_P30.PolicyControl(DB)
  Ind_MS_Biomass_Exo.PolicyControl(DB)

  #
  # Industrial Conversions (needs testing)
  #
  Ind_Conv_Initialize.PolicyControl(DB)
  Ind_Conv_BC_Elec.PolicyControl(DB)
  # Ind_Conv_All.PolicyControl(DB)

  #
  # Industrial Fungible Demands
  #
  # HydrogenResCom.PolicyControl(DB)
  Ind_H2_DemandsAP_RefA.PolicyControl(DB)
  Ind_H2_FeedstocksAP_RefA.PolicyControl(DB)

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
  LDV2_A.PolicyControl(DB)
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
  Trans_MS_Electric_Bus_A.PolicyControl(DB)
  Trans_MS_PREGTI_QC.PolicyControl(DB)
  Trans_MS_Freight_Modal_Shares.PolicyControl(DB)
  Trans_MS_iMHZEV.PolicyControl(DB)
  Trans_MS_FuelCell.PolicyControl(DB)
  Trans_MS_Marine.PolicyControl(DB)
  Trans_MS_LDV_CA.PolicyControl(DB)
  Trans_MS_HDV_CA.PolicyControl(DB)
  Trans_MS_Train_CA.PolicyControl(DB)

  #
  # Multiple Sectors
  # Any policies which change xMMSF, xDmFrac, or xFsFrac should be
  # split by sector and moved up in batch file - Jeff Amlin 2/4/25
  #
  OG_MRA_EMR.PolicyControl(DB)
  OG_Venting.PolicyControl(DB)
  # OG_OtherFugitives_IEACurves_EMR.PolicyControl(DB)
  # OG_Venting_IEACurves_EMR.PolicyControl(DB)
  HFCS.PolicyControl(DB)
  Eff_MB_Act.PolicyControl(DB)
  Waste_diversion.PolicyControl(DB)
  Waste_LFG.PolicyControl(DB)
  Res_CGHG.PolicyControl(DB)
  Res_CHMC_Loan.PolicyControl(DB)
  GHG_CCSCurves_RefA.PolicyControl(DB)
  # EIP_CCS_1.PolicyControl(DB)
  EIP_CCS_2_RefA.PolicyControl(DB)
  # CCS_Glacier.PolicyControl(DB)
  OG_CCS_Projects.PolicyControl(DB)
  # CCS_FedCoop_1.PolicyControl(DB)
  CCS_FedCoop_2.PolicyControl(DB)
  # CCS_Polaris.PolicyControl(DB)
  CCS_Polaris_2.PolicyControl(DB)
  CCS_HeidelbergLafarge_AB.PolicyControl(DB)
  CCS_Stelco_ON.PolicyControl(DB)
  CCS_ITC_RefA.PolicyControl(DB)

  #
  # RNG_Standard.PolicyControl(DB)
  #
  RNG_Standard_BC_A.PolicyControl(DB)
  RNG_Standard_QC.PolicyControl(DB)

  #
  # CAC
  #
  CAC_FreightStandards.PolicyControl(DB)
  CAC_PassStandards.PolicyControl(DB)
  CAC_NL_AirControlReg.PolicyControl(DB)
  CAC_NS_AirQualityReg.PolicyControl(DB)
  CAC_BLIERS.PolicyControl(DB)
  CAC_CCME_AcidRain_A.PolicyControl(DB)
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
  CAC_ELYSIS.PolicyControl(DB)

  #
  # Efficiency Improvements
  #
  # GHGNonEnergyPolicy.PolicyControl(DB)
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
  CFS_LiquidPrice_A.PolicyControl(DB)

  #
  # Additional Measures Policies
  # Any policies which change xMMSF, xDmFrac, or xFsFrac should be
  # split by sector and moved up in the batch file - Jeff Amlin 2/4/2
  #

  #
  # Built Environment Policies
  #
  Res_BldgNZ.PolicyControl(DB)
  Com_BldgNZ.PolicyControl(DB)

  #
  # PCF 3.0
  #
  # EndogenousElectricCapacity_2.PolicyControl(DB)
  # PCF_DeviceStd_Res.PolicyControl(DB)
  # PCF_DeviceStd_Com.PolicyControl(DB)
  # PCF_Retro_Com.PolicyControl(DB)
  # Trans_OffRoad_Electrify.PolicyControl(DB)
  # P30_Al_InertAnode.PolicyControl(DB)
  # P30_Ind_Process.PolicyControl(DB)
  # P30_Ind_SAGD.PolicyControl(DB)
  # OG_SAGD_Solvent.PolicyControl(DB)
  Active_Transportation.PolicyControl(DB)
  # CleanBC_CCS_NG.PolicyControl(DB)
  # LCFS_BC_A.PolicyControl(DB)
  Fertilizer_Reduction.PolicyControl(DB)
  Ag_ACT_CO2_reduction.PolicyControl(DB)
  OBPS_FC_Com.PolicyControl(DB)
  OBPS_FC_Ind.PolicyControl(DB)
  OBPS_FC_Manuf.PolicyControl(DB)
  OBPS_FC_OG.PolicyControl(DB)
  OBPS_FC_Agr.PolicyControl(DB)
  # ElecCostsRenew1.PolicyControl(DB)
  FixNH3PlantDemand.PolicyControl(DB)

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

  #
  #  Electricity Generation
  #
  
  #
  # Pre-processing: General parameters (Not-policy)
  #
  Electric_DeliveryCharge_Switch.PolicyControl(DB)
  Electric_Endogenous_Capacity.PolicyControl(DB)
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
  # Electric_ITCs.PolicyControl(DB)
  Electric_ITCs_AM.PolicyControl(DB)
  # Electricity_SREPS.PolicyControl(DB)
  Electric_BC_Offsets.PolicyControl(DB)
  Electric_NS_Renewable.PolicyControl(DB)
  Electric_NS_GHGLimit.PolicyControl(DB)
  Electric_CER_Endogenous_Units.PolicyControl(DB)
  # Electric_CER_Exogenous_Units.PolicyControl(DB)
  Electric_CER_Exogenous_Units_AM.PolicyControl(DB)
  Electric_CER_Exogenous_PCFMax.PolicyControl(DB)
  
  #
  # AM Policies
  #
  # Electric_AM_Capacity.PolicyControl(DB)
  Electric_AM_Transmission.PolicyControl(DB)
  Electric_AM_Transmission_Costs.PolicyControl(DB)
  Electric_AM_BC_Gas_Retire.PolicyControl(DB)
  
  #
  # Post-processing: Patches (Not-policy)
  #
  # Electric_Patch.PolicyControl(DB)
  Electric_Patch_AM.PolicyControl(DB)
  Electric_SK_Coal_Cost.PolicyControl(DB)
  # Electric_Patch_Exports.PolicyControl(DB)
  Electric_Patch_Exports_AM.PolicyControl(DB)
  Electric_NS_HydroPurchases.PolicyControl(DB)

  #
  # Oil and Gas Emissions Cap (OGEC)
  #
  # OGEC_Market.PolicyControl(DB)
  # OGEC_Prices.PolicyControl(DB)

  #
  # Carbon Tax with OBA
  #
  CarbonTax_OBA_ON.PolicyControl(DB)
  CarbonTax_OBA_NB.PolicyControl(DB)
  CarbonTax_OBA_SK.PolicyControl(DB)
  CarbonTax_OBA_NL.PolicyControl(DB)
  CarbonTax_OBA_AB.PolicyControl(DB)
  CarbonTax_OBA_NS.PolicyControl(DB)
  CarbonTax_OBA_BC.PolicyControl(DB)
  CarbonTax_OBA_Fed_170.PolicyControl(DB)

end

end

