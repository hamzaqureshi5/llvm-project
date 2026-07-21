// RUN: mlir-opt %s -convert-math-to-nvvm -split-input-file | FileCheck %s

module {
// CHECK-LABEL: func.func @fpclass_scalar
func.func @fpclass_scalar(%arg: f32) -> (i1, i1, i1) {
  // CHECK: llvm.call @__nv_isinff(
  %inf = math.isinf %arg : f32
  // CHECK: llvm.call @__nv_finitef(
  %finite = math.isfinite %arg : f32
  // CHECK: llvm.call @__nv_isnanf(
  %nan = math.isnan %arg : f32
  return %inf, %finite, %nan : i1, i1, i1
}
}

// -----

// Vectorized bool-result ops must scalarize (one call per lane) rather than
// crash. OpToFuncCallLowering used to assert here: it detected bool results
// by checking whether the *result type itself* was i1, which is never true
// for a vector<Nxi1> result, so it treated this as an unsupported
// same-operand-and-result-type mismatch instead of the known bool-result
// case.
module {
// CHECK-LABEL: func.func @fpclass_vector
func.func @fpclass_vector(%arg: vector<2xf32>) -> (vector<2xi1>, vector<2xi1>, vector<2xi1>) {
  %inf = math.isinf %arg : vector<2xf32>
  // CHECK-COUNT-2: llvm.call @__nv_isinff(
  %finite = math.isfinite %arg : vector<2xf32>
  // CHECK-COUNT-2: llvm.call @__nv_finitef(
  %nan = math.isnan %arg : vector<2xf32>
  // CHECK-COUNT-2: llvm.call @__nv_isnanf(
  return %inf, %finite, %nan : vector<2xi1>, vector<2xi1>, vector<2xi1>
}
}
