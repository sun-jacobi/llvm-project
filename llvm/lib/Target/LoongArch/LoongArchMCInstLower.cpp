//=- LoongArchMCInstLower.cpp - Convert LoongArch MachineInstr to an MCInst -=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains code to lower LoongArch MachineInstrs to their
// corresponding MCInst records.
//
//===----------------------------------------------------------------------===//

#include "LoongArch.h"
#include "MCTargetDesc/LoongArchBaseInfo.h"
#include "MCTargetDesc/LoongArchMCAsmInfo.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"

using namespace llvm;

static MCOperand lowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym,
                                    const AsmPrinter &AP) {
  MCContext &Ctx = AP.OutContext;
  uint16_t Kind = 0;

  switch (LoongArchII::getDirectFlags(MO)) {
  default:
    llvm_unreachable("Unknown target flag on GV operand");
  case LoongArchII::MO_None:
    Kind = LoongArchMCExpr::VK_None;
    break;
  case LoongArchII::MO_CALL:
  case LoongArchII::MO_CALL_PLT:
    Kind = ELF::R_LARCH_B26;
    break;
  case LoongArchII::MO_PCREL_HI:
    Kind = ELF::R_LARCH_PCALA_HI20;
    break;
  case LoongArchII::MO_PCREL_LO:
    Kind = ELF::R_LARCH_PCALA_LO12;
    break;
  case LoongArchII::MO_PCREL64_LO:
    Kind = ELF::R_LARCH_PCALA64_LO20;
    break;
  case LoongArchII::MO_PCREL64_HI:
    Kind = ELF::R_LARCH_PCALA64_HI12;
    break;
  case LoongArchII::MO_GOT_PC_HI:
    Kind = ELF::R_LARCH_GOT_PC_HI20;
    break;
  case LoongArchII::MO_GOT_PC_LO:
    Kind = ELF::R_LARCH_GOT_PC_LO12;
    break;
  case LoongArchII::MO_GOT_PC64_LO:
    Kind = ELF::R_LARCH_GOT64_PC_LO20;
    break;
  case LoongArchII::MO_GOT_PC64_HI:
    Kind = ELF::R_LARCH_GOT64_PC_HI12;
    break;
  case LoongArchII::MO_LE_HI:
    Kind = ELF::R_LARCH_TLS_LE_HI20;
    break;
  case LoongArchII::MO_LE_LO:
    Kind = ELF::R_LARCH_TLS_LE_LO12;
    break;
  case LoongArchII::MO_LE64_LO:
    Kind = ELF::R_LARCH_TLS_LE64_LO20;
    break;
  case LoongArchII::MO_LE64_HI:
    Kind = ELF::R_LARCH_TLS_LE64_HI12;
    break;
  case LoongArchII::MO_IE_PC_HI:
    Kind = ELF::R_LARCH_TLS_IE_PC_HI20;
    break;
  case LoongArchII::MO_IE_PC_LO:
    Kind = ELF::R_LARCH_TLS_IE_PC_LO12;
    break;
  case LoongArchII::MO_IE_PC64_LO:
    Kind = ELF::R_LARCH_TLS_IE64_PC_LO20;
    break;
  case LoongArchII::MO_IE_PC64_HI:
    Kind = ELF::R_LARCH_TLS_IE64_PC_HI12;
    break;
  case LoongArchII::MO_LD_PC_HI:
    Kind = ELF::R_LARCH_TLS_LD_PC_HI20;
    break;
  case LoongArchII::MO_GD_PC_HI:
    Kind = ELF::R_LARCH_TLS_GD_PC_HI20;
    break;
  case LoongArchII::MO_CALL36:
    Kind = ELF::R_LARCH_CALL36;
    break;
  case LoongArchII::MO_DESC_PC_HI:
    Kind = ELF::R_LARCH_TLS_DESC_PC_HI20;
    break;
  case LoongArchII::MO_DESC_PC_LO:
    Kind = ELF::R_LARCH_TLS_DESC_PC_LO12;
    break;
  case LoongArchII::MO_DESC64_PC_LO:
    Kind = ELF::R_LARCH_TLS_DESC64_PC_LO20;
    break;
  case LoongArchII::MO_DESC64_PC_HI:
    Kind = ELF::R_LARCH_TLS_DESC64_PC_HI12;
    break;
  case LoongArchII::MO_DESC_LD:
    Kind = ELF::R_LARCH_TLS_DESC_LD;
    break;
  case LoongArchII::MO_DESC_CALL:
    Kind = ELF::R_LARCH_TLS_DESC_CALL;
    break;
  case LoongArchII::MO_LE_HI_R:
    Kind = ELF::R_LARCH_TLS_LE_HI20_R;
    break;
  case LoongArchII::MO_LE_ADD_R:
    Kind = ELF::R_LARCH_TLS_LE_ADD_R;
    break;
  case LoongArchII::MO_LE_LO_R:
    Kind = ELF::R_LARCH_TLS_LE_LO12_R;
    break;
    // TODO: Handle more target-flags.
  }

  const MCExpr *ME = MCSymbolRefExpr::create(Sym, Ctx);

  if (!MO.isJTI() && !MO.isMBB() && MO.getOffset())
    ME = MCBinaryExpr::createAdd(
        ME, MCConstantExpr::create(MO.getOffset(), Ctx), Ctx);

  if (Kind != LoongArchMCExpr::VK_None)
    ME = LoongArchMCExpr::create(ME, Kind, Ctx, LoongArchII::hasRelaxFlag(MO));
  return MCOperand::createExpr(ME);
}

bool llvm::lowerLoongArchMachineOperandToMCOperand(const MachineOperand &MO,
                                                   MCOperand &MCOp,
                                                   const AsmPrinter &AP) {
  switch (MO.getType()) {
  default:
    report_fatal_error(
        "lowerLoongArchMachineOperandToMCOperand: unknown operand type");
  case MachineOperand::MO_Register:
    // Ignore all implicit register operands.
    if (MO.isImplicit())
      return false;
    MCOp = MCOperand::createReg(MO.getReg());
    break;
  case MachineOperand::MO_RegisterMask:
    // Regmasks are like implicit defs.
    return false;
  case MachineOperand::MO_Immediate:
    MCOp = MCOperand::createImm(MO.getImm());
    break;
  case MachineOperand::MO_ConstantPoolIndex:
    MCOp = lowerSymbolOperand(MO, AP.GetCPISymbol(MO.getIndex()), AP);
    break;
  case MachineOperand::MO_GlobalAddress:
    MCOp = lowerSymbolOperand(MO, AP.getSymbolPreferLocal(*MO.getGlobal()), AP);
    break;
  case MachineOperand::MO_MachineBasicBlock:
    MCOp = lowerSymbolOperand(MO, MO.getMBB()->getSymbol(), AP);
    break;
  case MachineOperand::MO_ExternalSymbol:
    MCOp = lowerSymbolOperand(
        MO, AP.GetExternalSymbolSymbol(MO.getSymbolName()), AP);
    break;
  case MachineOperand::MO_BlockAddress:
    MCOp = lowerSymbolOperand(
        MO, AP.GetBlockAddressSymbol(MO.getBlockAddress()), AP);
    break;
  case MachineOperand::MO_JumpTableIndex:
    MCOp = lowerSymbolOperand(MO, AP.GetJTISymbol(MO.getIndex()), AP);
    break;
  }
  return true;
}

bool llvm::lowerLoongArchMachineInstrToMCInst(const MachineInstr *MI,
                                              MCInst &OutMI, AsmPrinter &AP) {
  OutMI.setOpcode(MI->getOpcode());

  for (const MachineOperand &MO : MI->operands()) {
    MCOperand MCOp;
    if (lowerLoongArchMachineOperandToMCOperand(MO, MCOp, AP))
      OutMI.addOperand(MCOp);
  }
  return false;
}
