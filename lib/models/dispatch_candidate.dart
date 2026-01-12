/// 派发候选（用户信息）
///
/// 服务端示例：
/// {
///   "empName": "张三",
///   "empNo": "61002541",
///   "workGroup": "代经理",
///   "access_group": "运维团队_数字化BP_创新开发"
/// }
class DispatchCandidate {
  final String empName;
  final String empNo;
  final String? workGroup;
  final String? accessGroup;

  const DispatchCandidate({
    required this.empName,
    required this.empNo,
    this.workGroup,
    this.accessGroup,
  });

  factory DispatchCandidate.fromJson(Map<String, dynamic> json) {
    return DispatchCandidate(
      empName: (json['empName'] ?? '').toString(),
      empNo: (json['empNo'] ?? '').toString(),
      workGroup: json['workGroup']?.toString(),
      accessGroup: json['accessGroup']?.toString(),
    );
  }
}
