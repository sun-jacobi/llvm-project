; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -passes=instcombine -S | FileCheck %s

declare i64 @llvm.ctpop.i64(i64)
declare i32 @llvm.ctpop.i32(i32)
declare i16 @llvm.ctpop.i16(i16)
declare i8 @llvm.ctpop.i8(i8)
declare <2 x i32> @llvm.ctpop.v2i32(<2 x i32>)
declare <2 x i64> @llvm.ctpop.v2i64(<2 x i64>)
declare void @llvm.assume(i1)

define i16 @ctpop_x_and_negx(i16 %x) {
; CHECK-LABEL: @ctpop_x_and_negx(
; CHECK-NEXT:    [[V0:%.*]] = sub i16 0, [[X:%.*]]
; CHECK-NEXT:    [[V1:%.*]] = and i16 [[X]], [[V0]]
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ne i16 [[V1]], 0
; CHECK-NEXT:    [[CNT:%.*]] = zext i1 [[TMP1]] to i16
; CHECK-NEXT:    ret i16 [[CNT]]
;
  %v0 = sub i16 0, %x
  %v1 = and i16 %x, %v0
  %cnt = call i16 @llvm.ctpop.i16(i16 %v1)
  ret i16 %cnt
}

define i8 @ctpop_x_nz_and_negx(i8 %x) {
; CHECK-LABEL: @ctpop_x_nz_and_negx(
; CHECK-NEXT:    ret i8 1
;
  %x1 = or i8 %x, 1
  %v0 = sub i8 0, %x1
  %v1 = and i8 %x1, %v0
  %cnt = call i8 @llvm.ctpop.i8(i8 %v1)
  ret i8 %cnt
}

define i32 @ctpop_2_shl(i32 %x) {
; CHECK-LABEL: @ctpop_2_shl(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ult i32 [[X:%.*]], 31
; CHECK-NEXT:    [[CNT:%.*]] = zext i1 [[TMP1]] to i32
; CHECK-NEXT:    ret i32 [[CNT]]
;
  %v = shl i32 2, %x
  %cnt = call i32 @llvm.ctpop.i32(i32 %v)
  ret i32 %cnt
}

define i32 @ctpop_2_shl_nz(i32 %x) {
; CHECK-LABEL: @ctpop_2_shl_nz(
; CHECK-NEXT:    ret i32 1
;
  %xa30 = and i32 30, %x
  %v = shl i32 2, %xa30
  %cnt = call i32 @llvm.ctpop.i32(i32 %v)
  ret i32 %cnt
}

define i8 @ctpop_imin_plus1_lshr_nz(i8 %x) {
; CHECK-LABEL: @ctpop_imin_plus1_lshr_nz(
; CHECK-NEXT:    [[CMP:%.*]] = icmp ne i8 [[X:%.*]], 0
; CHECK-NEXT:    call void @llvm.assume(i1 [[CMP]])
; CHECK-NEXT:    [[V:%.*]] = lshr i8 -127, [[X]]
; CHECK-NEXT:    [[CNT:%.*]] = call range(i8 1, 9) i8 @llvm.ctpop.i8(i8 [[V]])
; CHECK-NEXT:    ret i8 [[CNT]]
;
  %cmp = icmp ne i8 %x, 0
  call void @llvm.assume(i1 %cmp)
  %v = lshr i8 129, %x
  %cnt = call i8 @llvm.ctpop.i8(i8 %v)
  ret i8 %cnt
}


define i64 @ctpop_x_and_negx_nz(i64 %x) {
; CHECK-LABEL: @ctpop_x_and_negx_nz(
; CHECK-NEXT:    [[V0:%.*]] = sub i64 0, [[X:%.*]]
; CHECK-NEXT:    [[V1:%.*]] = and i64 [[X]], [[V0]]
; CHECK-NEXT:    [[CMP:%.*]] = icmp ne i64 [[V1]], 0
; CHECK-NEXT:    call void @llvm.assume(i1 [[CMP]])
; CHECK-NEXT:    ret i64 1
;
  %v0 = sub i64 0, %x
  %v1 = and i64 %x, %v0
  %cmp = icmp ne i64 %v1, 0
  call void @llvm.assume(i1 %cmp)
  %cnt = call i64 @llvm.ctpop.i64(i64 %v1)
  ret i64 %cnt
}

define <2 x i32> @ctpop_shl2_1_vec(<2 x i32> %x) {
; CHECK-LABEL: @ctpop_shl2_1_vec(
; CHECK-NEXT:    [[SHL:%.*]] = shl <2 x i32> <i32 2, i32 1>, [[X:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ne <2 x i32> [[SHL]], zeroinitializer
; CHECK-NEXT:    [[CNT:%.*]] = zext <2 x i1> [[TMP1]] to <2 x i32>
; CHECK-NEXT:    ret <2 x i32> [[CNT]]
;
  %shl = shl <2 x i32> <i32 2 ,i32 1>, %x
  %cnt = call <2 x i32> @llvm.ctpop.v2i32(<2 x i32> %shl)
  ret <2 x i32> %cnt
}


define <2 x i32> @ctpop_lshr_intmin_intmin_plus1_vec_nz(<2 x i32> %x) {
; CHECK-LABEL: @ctpop_lshr_intmin_intmin_plus1_vec_nz(
; CHECK-NEXT:    [[X1:%.*]] = or <2 x i32> [[X:%.*]], splat (i32 1)
; CHECK-NEXT:    [[SHR:%.*]] = lshr <2 x i32> <i32 -2147483648, i32 -2147483647>, [[X1]]
; CHECK-NEXT:    [[CNT:%.*]] = call range(i32 1, 17) <2 x i32> @llvm.ctpop.v2i32(<2 x i32> [[SHR]])
; CHECK-NEXT:    ret <2 x i32> [[CNT]]
;
  %x1 = or <2 x i32> %x, <i32 1 ,i32 1>
  %shr = lshr <2 x i32> <i32 2147483648 ,i32 2147483649>, %x1
  %cnt = call <2 x i32> @llvm.ctpop.v2i32(<2 x i32> %shr)
  ret <2 x i32> %cnt
}


define <2 x i32> @ctpop_shl2_1_vec_nz(<2 x i32> %x) {
; CHECK-LABEL: @ctpop_shl2_1_vec_nz(
; CHECK-NEXT:    ret <2 x i32> splat (i32 1)
;
  %and = and <2 x i32> %x, <i32 15 ,i32 15>
  %shl = shl <2 x i32> <i32 2 ,i32 1>, %and
  %cnt = call <2 x i32> @llvm.ctpop.v2i32(<2 x i32> %shl)
  ret <2 x i32> %cnt
}

define <2 x i64> @ctpop_x_and_negx_vec(<2 x i64> %x) {
; CHECK-LABEL: @ctpop_x_and_negx_vec(
; CHECK-NEXT:    [[SUB:%.*]] = sub <2 x i64> zeroinitializer, [[X:%.*]]
; CHECK-NEXT:    [[AND:%.*]] = and <2 x i64> [[X]], [[SUB]]
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ne <2 x i64> [[AND]], zeroinitializer
; CHECK-NEXT:    [[CNT:%.*]] = zext <2 x i1> [[TMP1]] to <2 x i64>
; CHECK-NEXT:    ret <2 x i64> [[CNT]]
;
  %sub = sub <2 x i64> <i64 0 ,i64 0>, %x
  %and = and <2 x i64> %sub, %x
  %cnt = call <2 x i64> @llvm.ctpop.v2i64(<2 x i64> %and)
  ret <2 x i64> %cnt
}

define <2 x i32> @ctpop_x_and_negx_vec_nz(<2 x i32> %x) {
; CHECK-LABEL: @ctpop_x_and_negx_vec_nz(
; CHECK-NEXT:    ret <2 x i32> splat (i32 1)
;
  %x1 = or <2 x i32> %x, <i32 1 ,i32 1>
  %sub = sub <2 x i32> <i32 0 ,i32 0>, %x1
  %and = and <2 x i32> %sub, %x1
  %cnt = call <2 x i32> @llvm.ctpop.v2i32(<2 x i32> %and)
  ret <2 x i32> %cnt
}
