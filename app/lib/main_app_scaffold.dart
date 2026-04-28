// import 'package:flutter/material.dart';
// import 'package:b612_1/models/mission.dart';
// // app_shell.dart에서 UserProfile 클래스를 가져옵니다.
// // 만약 UserProfile이 다른 곳(models/user_profile.dart)에 있다면 그 경로로 수정하세요.
// import 'package:b612_1/app_shell.dart' show UserProfile;
// import 'package:b612_1/screens/today_tab/today_tab_screen.dart'; // 주의: Step 1에서 HomeTabScreen으로 이름을 바꿨다면 경로 확인 필요
// // import 'package:b612_1/screens/home_tab/home_tab_screen.dart'; // 만약 HomeTabScreen을 쓴다면 이걸로 교체
// import 'package:b612_1/screens/mission_browser/mission_browser_screen.dart';
// import 'package:b612_1/screens/history_tab/history_tab_screen.dart';
// import 'package:b612_1/screens/profile_screen/profile_screen.dart';
//
// class MainAppScaffold extends StatefulWidget {
//   final List<Mission> missions;
//   final Map<String, bool> attendanceData;
//   final Set<String> addedMissionIds;
//   final UserProfile userProfile;
//   final Function(String) onToggleMission;
//   final VoidCallback onAddMission;
//   final Function(String, String?) onAddPhoto;
//   final Function(String) onDeleteMission;
//   final Function(Mission, String?) onAddMissionFromBrowser;
//   final Function(UserProfile) onUpdateProfile;
//   final VoidCallback onLogout;
//
//   const MainAppScaffold({
//     super.key,
//     required this.missions,
//     required this.attendanceData,
//     required this.addedMissionIds,
//     required this.userProfile,
//     required this.onToggleMission,
//     required this.onAddMission,
//     required this.onAddPhoto,
//     required this.onDeleteMission,
//     required this.onAddMissionFromBrowser,
//     required this.onUpdateProfile,
//     required this.onLogout,
//   });
//
//   @override
//   State<MainAppScaffold> createState() => _MainAppScaffoldState();
// }
//
// class _MainAppScaffoldState extends State<MainAppScaffold> {
//   int _currentTabIndex = 1;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   void _onTabTapped(int index) {
//     setState(() {
//       _currentTabIndex = index;
//     });
//   }
//
//   void _handleNavigateToProfile() {
//     setState(() {
//       _currentTabIndex = 3;
//     });
//   }
//
//   void _handleNavigateToRecords() {
//     setState(() {
//       _currentTabIndex = 2;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final List<Widget> tabPages = [
//       // 0. 탐색 탭
//       MissionBrowserScreen(
//         onAddMission: widget.onAddMissionFromBrowser,
//         addedMissionIds: widget.addedMissionIds,
//       ),
//
//       // 1. 오늘 탭 (기존 TodayTabScreen 유지)
//       // 만약 HomeTabScreen으로 교체하고 싶다면 아래 주석을 참고하세요.
//       TodayTabScreen(
//         missions: widget.missions,
//         attendanceData: widget.attendanceData,
//         onToggleMission: widget.onToggleMission,
//         onAddMission: widget.onAddMission,
//         onAddPhoto: widget.onAddPhoto,
//         onDeleteMission: widget.onDeleteMission,
//       ),
//
//       // 2. 기록 탭 [수정된 부분]
//       HistoryTabScreen(
//         onOpenProfile: () => _handleNavigateToProfile(),
//         // [수정] attendanceData와 userProfile 전달 (필수 파라미터)
//         attendanceData: widget.attendanceData,
//         userProfile: widget.userProfile,
//         // [삭제] profileEmoji, userBio는 더 이상 사용하지 않음
//       ),
//
//       // 3. 프로필 탭 [수정된 부분]
//       ProfileScreen(
//         userProfile: widget.userProfile,
//         onBack: () => _handleNavigateToRecords(),
//         onLogout: widget.onLogout,
//         // [삭제] onUpdateProfile 파라미터 제거 (Step 4의 ProfileScreen 정의에 없음)
//       ),
//     ];
//
//     // 프로필 화면(index 3)일 때 네비게이션 바에서는 '기록(index 2)'이 선택된 것처럼 보이게 함
//     int bottomNavIndex = (_currentTabIndex == 3) ? 2 : _currentTabIndex;
//
//     return Scaffold(
//       body: IndexedStack(
//         index: _currentTabIndex,
//         children: tabPages,
//       ),
//       bottomNavigationBar: _CustomBottomNavBar(
//         currentIndex: bottomNavIndex,
//         onTap: _onTabTapped,
//       ),
//     );
//   }
// }
//
// class _CustomBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final Function(int) onTap;
//
//   const _CustomBottomNavBar({required this.currentIndex, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 70.0,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1.0)),
//       ),
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               _buildNavItem(
//                 icon: Icons.search,
//                 label: '탐색',
//                 index: 0,
//                 onTap: () => onTap(0),
//               ),
//               const Spacer(),
//               _buildNavItem(
//                 icon: Icons.calendar_month,
//                 label: '기록',
//                 index: 2,
//                 onTap: () => onTap(2),
//               ),
//             ],
//           ),
//           Positioned(
//             bottom: 8.0,
//             child: GestureDetector(
//               onTap: () => onTap(1),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 transform: Matrix4.translationValues(
//                     0.0, currentIndex == 1 ? -16.0 : -8.0, 0.0)
//                   ..scale(currentIndex == 1 ? 1.1 : 1.0),
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFF8C42),
//                   borderRadius: BorderRadius.circular(24.0),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 10.0,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: const Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.home, size: 20.0, color: Colors.white),
//                     SizedBox(height: 2.0),
//                     Text('오늘',
//                         style: TextStyle(color: Colors.white, fontSize: 12.0)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem({
//     required IconData icon,
//     required String label,
//     required int index,
//     required VoidCallback onTap,
//   }) {
//     final bool isSelected = currentIndex == index;
//     final Color color =
//     isSelected ? const Color(0xFFFF8C42) : Colors.grey.shade500;
//
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           color: isSelected ? Colors.orange.shade50 : Colors.transparent,
//           padding: const EdgeInsets.symmetric(vertical: 12.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(icon, size: 20.0, color: color),
//               const SizedBox(height: 4.0),
//               Text(label, style: TextStyle(fontSize: 12.0, color: color)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }