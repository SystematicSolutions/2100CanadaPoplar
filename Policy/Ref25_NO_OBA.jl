#
# Ref25.jl - Ref25 plus CP 170 policies
#

module Policy

import ...EnergyModel: DB

#
include("PatchFsPOCXTrans.jl")
include("SetAsReferenceCase.jl")
include("Elec_Exports_Patch.jl")
include("Ammonia_Exports.jl")
include("Hydrogen_Prices.jl")

include("ElectricDeliveryCharge_Switch.jl")

#
#  Biofuels and Solar
#
include("KPIA_Biofuels_Prov.jl")
include("LCFS_BC.jl")

#
#  Residential and Commercial Building Code
#
include("Com_BldgStdPolicy.jl")
include("Res_BldgStdPolicy.jl")

#
#  QC Process Retrofit
#
include("QC_EcoPerf_Com.jl")

#
#  Residential and Commercial Equipment Standards
#
include("StdEq_Com_U19.jl")
include("StdEq_Res_U19.jl")

#
#  Residential and Commercial LCEF
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
#  Residential Market Shares
#
include("Res_MS_Initialize.jl")
include("Res_MS_Electric_NL.jl")
include("Res_MS_Biomass_NT.jl")
include("Res_MS_HeatPump_BC.jl")
include("Res_MS_HeatPump_NRCAN.jl")
include("Res_MS_NewElectric_CA.jl")
include("Res_MS_Normalize.jl")
include("Res_MS_Coefficient.jl")
include("Res_MS_Conversions.jl")
include("Res_MS_ConvElectric_CA.jl")

#
#  Commercial Market Shares
#
include("Com_MS_Initialize.jl")
include("Com_MS_Electric_NL.jl")
include("Com_MS_Biomass_NT.jl")
include("Com_MS_HeatPump_BC.jl")
include("Com_MS_LCEFC.jl")
include("Com_MS_NewElectric_CA.jl")
include("Com_MS_Normalize.jl")
include("Com_MS_Coefficient.jl")
include("Com_MS_Conversions.jl")
include("Com_MS_ConvElectric_CA.jl")

#
#  NRCan RDD Projects
#
include("ResCom_EIP.jl")

#
#  Industrial
#
include("Ind_MS_Initialize.jl")
include("Ind_Fungible_Initialize.jl")
include("Ind_FungibleFS_Initialize.jl")
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
#  Industrial Market Shares
#
include("Ind_MS_Elec_PeaceRiverBC.jl")
include("Ind_MS_IronSteel.jl")
include("Ind_MS_LCEF_EIP.jl")
include("Ind_MS_OCNL.jl")

#
#  Industrial Conversions (needs testing)
#
include("Ind_Conv_Initialize.jl")
include("Ind_Conv_BC_Elec.jl")

#
#  Industrial Fungible Demands
#
# include("Ind_Fungible_Initialize.jl")
include("Ind_H2_DemandsAP.jl")
include("Ind_H2_FeedstocksAP.jl")

#
# Industrial End of Policies Normalize and Calculate Coefficients
#
include("Ind_MS_Normalize.jl")
include("Ind_Fungible_Normalize.jl")
include("Ind_FungibleFS_Normalize.jl")
include("Ind_MS_Coefficient.jl")
include("Ind_Fungible_Coefficients.jl")
include("Ind_FungibleFS_Coefficients.jl")

# This policy must be run after the calcuation of market share
# coefficients.  We need to revise the code to remove the use
# of having xMMSF set equal to -99 - Jeff Amlin 2/4/25
#
include("Ind_MS_Biomass_Exo.jl")

#
# Hydrogen Supply
#
include("H2_Supply.jl")
include("Hydrogen_ITC.jl")

#
#  Transportation
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
#  Transportation Market Shares
#
include("Trans_MS_Initialize.jl")
include("Trans_MS_LDV_Electric.jl")
include("Trans_MS_Bus_Train.jl")
include("Trans_MS_PREGTI_QC.jl")
include("Trans_MS_Freight_Modal_Shares.jl")
include("Trans_MS_HDV_Electric_BC.jl")
include("Trans_MS_iMHZEV.jl")
include("Trans_MS_LDV_CA.jl")
include("Trans_MS_HDV_CA.jl")
include("Trans_MS_Train_CA.jl")
include("Trans_MS_Normalize.jl")
include("Trans_MS_Coefficient.jl")
include("Trans_MS_Conversions.jl")
include("Trans_MS_Conversions_CA.jl")

#
#  Multiple Sectors
#  Any policies which change xMMSF, xDmFrac, or xFsFrac should be
#  split by sector and moved up in batch file - Jeff Amlin 2/4/25
#
include("OG_MRA.jl")
include("OG_Venting.jl")
# include("OG_OtherFugitives_IEACurves_EMR.jl")
# include("OG_Venting_IEACurves_EMR.jl")
include("HFCS.jl")
include("Eff_MB_Act.jl")
include("Waste_diversion.jl")
#include("Waste_LFG.jl")
include("Res_CGHG.jl")
include("Res_CHMC_Loan.jl")
include("EIP_CCS_2.jl")
include("GHG_CCSCurves.jl")
include("CCS_ITC.jl")
include("CCS_Heidelberg_AB.jl")

include("RNG_Standard_BC.jl")
include("RNG_Standard_QC.jl")

#
#  Electric Generation
#
include("Electric_Renew_NS.jl")
include("EndogenousElectricCapacity.jl")
include("FixOutageRates.jl")
include("Electricity_Patch.jl")

#
#  CAC
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
#  Efficiency Improvements
#
# include("GHGNonEnergyPolicy.jl")
include("AdjustEnergyIntensity_Petroleum.jl")

#
#  Ontario Conservation Measures
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
#  SK Electric Unit Costs
#
include("Electric_Costs_SK_Coal.jl")

#
#  BC Electric Offsets Policy
#
include("Electric_Offsets_BC.jl")

#
#  National Coal Electric Performance Standard
#
include("Electric_Fed_Coal_Retire.jl")
include("Electric_Fed_Coal_Amendment.jl")

#
#  Nova Scotia Electric Performance Standard
#
include("EPS_NS_GHGLimit.jl")
include("EPS_NS_HydroPurchases.jl")

#
#  NRCan Electricity Policies
#
#include("Interties.jl")
include("NRCan_Elec_EmergingRenewables.jl")
include("NRCan_Elec_SmallCommunities.jl")
include("NRCan_Elec_SmartGrid_Energy.jl")
include("NRCan_Elec_SmartGrid_Peak.jl")

#
#  Non-CO2 Reduction Curves
#
include("GHG_Ind_ProcessReductionCurves.jl")
include("HFC_ReductionCurves_ON_QC.jl")

#
#  Electricity ITC's (Budget 2022 / FES 2022 / Budget 2023) and SREPs (NextGrid)
#
include("Electricity_ITCs.jl")
# include("Electricity_SREPS.jl")

#
#  ************************
#
#  Exogenous Clean Fuel Standard
#
#    #  Call PrmFile PCF_Ind_DmFrac_PetroCoke.txp
#    #  Call PrmFile PCF_Ind_DmFrac_HFO.txp
#  Call PrmFile TR_BF2.txp
#  Call PrmFile TR-Biofuels-PK3.txp
#  Call PrmFile OffRoad_BF4_noRNG.txp
#  Call PrmFile RBuild_BF3_noRNG.txp
#  Call PrmFile CBuild_BF3_noRNG.txp
#  Call PrmFile Ind_BF4_noRNG.txp
#  Call PrmFile Adjust_Biod_Max_CFR.txp
#    # Call PrmFile CCS_CFR_Exo_LOM.txp
#    # Call PrmFile CCS_CFR_Exo_OSU.txp
#  Call PrmFile CCS_CFR_Exo_Petro.txp
#
#  Endogenous Clean Fuel Standard
#
include("CFS_LiquidEVCredit.jl")
include("CFS_LiquidNGCredit.jl")
include("CFS_LiquidMarket_CN.jl")
include("CFS_LiquidPrice.jl")

#
#  Electric Units not selling to the grid in the Baseline (NextGrid)
#
include("UnitNoGrid_NoPSo.jl")

#
#  California Policies (except market share and conversion policies)
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
#  Clean Electricity Regulations
#
include("Electric_PCFMax_Unit_CER.jl")
include("Electric_NextGrid_input_for_CER.jl")
include("NextGrid_PCFMax_CER.jl")


#
#  Carbon Tax with OBA
#
include("CarbonTax_OBA_ON.jl")
include("CarbonTax_OBA_NB.jl")
include("CarbonTax_OBA_SK.jl")
include("CarbonTax_OBA_NL.jl")
include("CarbonTax_OBA_AB.jl")
include("CarbonTax_OBA_NS.jl")
include("CarbonTax_OBA_BC.jl")
include("CarbonTax_OBA_Fed_170.jl")
include("CarbonTax_OBARemoval.jl")

function IncorporatePolicies()
  @info "IncorporatePolicies"

  PatchFsPOCXTrans.PolicyControl(DB)
  SetAsReferenceCase.PolicyControl(DB)
  Elec_Exports_Patch.PolicyControl(DB)
  Ammonia_Exports.PolicyControl(DB)
  Hydrogen_Prices.PolicyControl(DB)

  ElectricDeliveryCharge_Switch.PolicyControl(DB)

  #
  #  Biofuels and Solar
  #
  KPIA_Biofuels_Prov.PolicyControl(DB)
  LCFS_BC.PolicyControl(DB)

  #
  #  Residential and Commercial Building Code
  #
  Com_BldgStdPolicy.PolicyControl(DB)
  Res_BldgStdPolicy.PolicyControl(DB)

  #
  #  QC Process Retrofit
  #
  QC_EcoPerf_Com.PolicyControl(DB)

  #
  #  Residential and Commercial Equipment Standards
  #
  StdEq_Com_U19.PolicyControl(DB)
  StdEq_Res_U19.PolicyControl(DB)

  #
  #  Residential and Commercial LCEF
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
  #  Residential Market Shares
  #
  Res_MS_Initialize.PolicyControl(DB)
  Res_MS_Electric_NL.PolicyControl(DB)
  Res_MS_Biomass_NT.PolicyControl(DB)
  Res_MS_HeatPump_BC.PolicyControl(DB)
  Res_MS_HeatPump_NRCAN.PolicyControl(DB)
  Res_MS_NewElectric_CA.PolicyControl(DB)
  Res_MS_Normalize.PolicyControl(DB)
  Res_MS_Coefficient.PolicyControl(DB)
  Res_MS_Conversions.PolicyControl(DB)
  Res_MS_ConvElectric_CA.PolicyControl(DB)

  #
  #  Commercial Market Shares
  #
  Com_MS_Initialize.PolicyControl(DB)
  Com_MS_Electric_NL.PolicyControl(DB)
  Com_MS_Biomass_NT.PolicyControl(DB)
  Com_MS_HeatPump_BC.PolicyControl(DB)
  Com_MS_LCEFC.PolicyControl(DB)
  Com_MS_NewElectric_CA.PolicyControl(DB)
  Com_MS_Normalize.PolicyControl(DB)
  Com_MS_Coefficient.PolicyControl(DB)
  Com_MS_Conversions.PolicyControl(DB)
  Com_MS_ConvElectric_CA.PolicyControl(DB)

  #
  #  NRCan RDD Projects
  #
  ResCom_EIP.PolicyControl(DB)

  #
  #  Industrial
  #
  Ind_MS_Initialize.PolicyControl(DB)
  Ind_Fungible_Initialize.PolicyControl(DB)
  Ind_FungibleFS_Initialize.PolicyControl(DB)

  Ind_Biomass_QC.PolicyControl(DB)
  Ind_LCEF_Dev.PolicyControl(DB)
  Ind_LCEF_Leader.PolicyControl(DB)
  Ind_LCEF_Pro.PolicyControl(DB)
  Ind_EnM.PolicyControl(DB)
  Ind_EcoPerformQC.PolicyControl(DB)
  AdjustCAC_Steel_2024.PolicyControl(DB)
  Ind_PeakSavings.PolicyControl(DB)
  #   Ind_NRC_EIP.PolicyControl(DB)
  #   Ind_Elec.PolicyControl(DB)
  Ind_NG.PolicyControl(DB)
  Ind_CleanBC_Cmnt.PolicyControl(DB)
  Ind_CleanBC_PP.PolicyControl(DB)
  Ind_CleanBC_SourGas.PolicyControl(DB)
  Ind_CleanBC_UnConv.PolicyControl(DB)
  #Ind_AB_Cement.PolicyControl(DB)
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
  #  Industrial Market Shares
  #
  Ind_MS_Elec_PeaceRiverBC.PolicyControl(DB)
  Ind_MS_IronSteel.PolicyControl(DB)
  Ind_MS_LCEF_EIP.PolicyControl(DB)
  Ind_MS_OCNL.PolicyControl(DB)

  #
  #  Industrial Conversions (needs testing)
  #
  Ind_Conv_Initialize.PolicyControl(DB)
  Ind_Conv_BC_Elec.PolicyControl(DB)

  #
  #  Industrial Fungible Demands
  #
  Ind_H2_DemandsAP.PolicyControl(DB)
  Ind_H2_FeedstocksAP.PolicyControl(DB)

  #
  # Industrial End of Policies Normalize and Calculate Coefficients
  #
  Ind_MS_Normalize.PolicyControl(DB)
  Ind_Fungible_Normalize.PolicyControl(DB)
  Ind_FungibleFS_Normalize.PolicyControl(DB)
  Ind_MS_Coefficient.PolicyControl(DB)
  Ind_Fungible_Coefficients.PolicyControl(DB)
  Ind_FungibleFS_Coefficients.PolicyControl(DB)

  #
  # This policy must be run after the calcuation of market share
  # coefficients.  We need to revise the code to remove the use
  # of having xMMSF set equal to -99 - Jeff Amlin 2/4/25
  #
  Ind_MS_Biomass_Exo.PolicyControl(DB)

  #
  # Hydrogen Supply
  #
  H2_Supply.PolicyControl(DB)
  Hydrogen_ITC.PolicyControl(DB)

  #
  #  Transportation
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
  #  Transportation Market Shares
  #
  Trans_MS_Initialize.PolicyControl(DB)
  Trans_MS_LDV_Electric.PolicyControl(DB)
  Trans_MS_Bus_Train.PolicyControl(DB)
  Trans_MS_PREGTI_QC.PolicyControl(DB)
  Trans_MS_Freight_Modal_Shares.PolicyControl(DB)
  Trans_MS_HDV_Electric_BC.PolicyControl(DB)
  Trans_MS_iMHZEV.PolicyControl(DB)
  Trans_MS_LDV_CA.PolicyControl(DB)
  Trans_MS_HDV_CA.PolicyControl(DB)
  Trans_MS_Train_CA.PolicyControl(DB)
  Trans_MS_Normalize.PolicyControl(DB)
  Trans_MS_Coefficient.PolicyControl(DB)
  Trans_MS_Conversions.PolicyControl(DB)
  Trans_MS_Conversions_CA.PolicyControl(DB)

  #
  #  Multiple Sectors
  #  Any policies which change xMMSF, xDmFrac, or xFsFrac should be
  #  split by sector and moved up in batch file - Jeff Amlin 2/4/25
  #
  OG_MRA.PolicyControl(DB)
  OG_Venting.PolicyControl(DB)
  # OG_OtherFugitives_IEACurves_EMR.PolicyControl(DB)
  # OG_Venting_IEACurves_EMR.PolicyControl(DB)
  HFCS.PolicyControl(DB)
  Eff_MB_Act.PolicyControl(DB)
  Waste_diversion.PolicyControl(DB)
  #Waste_LFG.PolicyControl(DB)
  Res_CGHG.PolicyControl(DB)
  Res_CHMC_Loan.PolicyControl(DB)
  EIP_CCS_2.PolicyControl(DB)
  GHG_CCSCurves.PolicyControl(DB)
  CCS_ITC.PolicyControl(DB)
  CCS_Heidelberg_AB.PolicyControl(DB)

  RNG_Standard_BC.PolicyControl(DB)
  RNG_Standard_QC.PolicyControl(DB)

  #
  #  Electric Generation
  #
  Electric_Renew_NS.PolicyControl(DB)
  EndogenousElectricCapacity.PolicyControl(DB)
  FixOutageRates.PolicyControl(DB)
  Electricity_Patch.PolicyControl(DB)

  #
  #  CAC
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
  CAC_Hg_Products.PolicyControl(DB)
  AdjustCAC_NL_Elec.PolicyControl(DB)
  AdjustCAC_NB_Elec.PolicyControl(DB)
  CAC_ON_CarbonBlack.PolicyControl(DB)
  CAC_VOCII_Reg.PolicyControl(DB)
  AdjustCAC_SK_Cogen.PolicyControl(DB)
  AdjustCAC_BC_Mercury.PolicyControl(DB)

  #
  #  Efficiency Improvements
  #
  AdjustEnergyIntensity_Petroleum.PolicyControl(DB)

  #
  #  Ontario Conservation Measures
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
  #  SK Electric Unit Costs
  #
  Electric_Costs_SK_Coal.PolicyControl(DB)

  #
  #  BC Electric Offsets Policy
  #
  Electric_Offsets_BC.PolicyControl(DB)

  #
  #  National Coal Electric Performance Standard
  #
  Electric_Fed_Coal_Retire.PolicyControl(DB)
  Electric_Fed_Coal_Amendment.PolicyControl(DB)

  #
  #  Nova Scotia Electric Performance Standard
  #
  EPS_NS_GHGLimit.PolicyControl(DB)
  EPS_NS_HydroPurchases.PolicyControl(DB)

  #
  #  NRCan Electricity Policies
  #
  #Interties.PolicyControl(DB)
  NRCan_Elec_EmergingRenewables.PolicyControl(DB)
  NRCan_Elec_SmallCommunities.PolicyControl(DB)
  NRCan_Elec_SmartGrid_Energy.PolicyControl(DB)
  NRCan_Elec_SmartGrid_Peak.PolicyControl(DB)

  #
  #  Non-CO2 Reduction Curves
  #
  GHG_Ind_ProcessReductionCurves.PolicyControl(DB)
  HFC_ReductionCurves_ON_QC.PolicyControl(DB)

  #
  #  Electricity ITC's (Budget 2022 / FES 2022 / Budget 2023) and SREPs (NextGrid)
  #
  Electricity_ITCs.PolicyControl(DB)
  #Electricity_SREPS.PolicyControl(DB)

  #
  #  ************************
  #
  #  Exogenous Clean Fuel Standard
  #
  #    #  Call PrmFile PCF_Ind_DmFrac_PetroCoke.txp
  #    #  Call PrmFile PCF_Ind_DmFrac_HFO.txp
  #  Call PrmFile TR_BF2.txp
  #  Call PrmFile TR-Biofuels-PK3.txp
  #  Call PrmFile OffRoad_BF4_noRNG.txp
  #  Call PrmFile RBuild_BF3_noRNG.txp
  #  Call PrmFile CBuild_BF3_noRNG.txp
  #  Call PrmFile Ind_BF4_noRNG.txp
  #  Call PrmFile Adjust_Biod_Max_CFR.txp
  #    # Call PrmFile CCS_CFR_Exo_LOM.txp
  #    # Call PrmFile CCS_CFR_Exo_OSU.txp
  #  Call PrmFile CCS_CFR_Exo_Petro.txp

  #
  #  Endogenous Clean Fuel Standard
  #
  CFS_LiquidEVCredit.PolicyControl(DB)
  CFS_LiquidNGCredit.PolicyControl(DB)
  CFS_LiquidMarket_CN.PolicyControl(DB)
  CFS_LiquidPrice.PolicyControl(DB)

  #
  #  Electric Units not selling to the grid in the Baseline (NextGrid)
  #
  UnitNoGrid_NoPSo.PolicyControl(DB)

  #
  #  California Policies (except market share and conversion policies)
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
  # Clean Electricity Regulations
  #
  Electric_PCFMax_Unit_CER.PolicyControl(DB)
  Electric_NextGrid_input_for_CER.PolicyControl(DB)
  NextGrid_PCFMax_CER.PolicyControl(DB)


  #
  #  Carbon Tax with OBA
  #
  CarbonTax_OBA_ON.PolicyControl(DB)
  CarbonTax_OBA_NB.PolicyControl(DB)
  CarbonTax_OBA_SK.PolicyControl(DB)
  CarbonTax_OBA_NL.PolicyControl(DB)
  CarbonTax_OBA_AB.PolicyControl(DB)
  CarbonTax_OBA_NS.PolicyControl(DB)
  CarbonTax_OBA_BC.PolicyControl(DB)
  CarbonTax_OBA_Fed_170.PolicyControl(DB)
  CarbonTax_OBARemoval.PolicyControl(DB)

end

end

