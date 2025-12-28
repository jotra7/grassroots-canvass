import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'platform_utils.dart';

/// Provides platform-adaptive icons.
/// Returns Material icons on Android/Web and Cupertino icons on iOS/macOS.
class AdaptiveIcons {
  // Navigation
  static IconData get list =>
      PlatformUtils.isApple ? CupertinoIcons.list_bullet : Icons.list;

  static IconData get listAlt =>
      PlatformUtils.isApple ? CupertinoIcons.list_bullet : Icons.list_alt;

  static IconData get map =>
      PlatformUtils.isApple ? CupertinoIcons.map : Icons.map;

  static IconData get mapOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.map : Icons.map_outlined;

  static IconData get settings =>
      PlatformUtils.isApple ? CupertinoIcons.settings : Icons.settings;

  static IconData get settingsOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.settings : Icons.settings_outlined;

  static IconData get home =>
      PlatformUtils.isApple ? CupertinoIcons.home : Icons.home;

  static IconData get homeOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.home : Icons.home_outlined;

  // Actions
  static IconData get search =>
      PlatformUtils.isApple ? CupertinoIcons.search : Icons.search;

  static IconData get add =>
      PlatformUtils.isApple ? CupertinoIcons.add : Icons.add;

  static IconData get edit =>
      PlatformUtils.isApple ? CupertinoIcons.pencil : Icons.edit;

  static IconData get delete =>
      PlatformUtils.isApple ? CupertinoIcons.trash : Icons.delete;

  static IconData get deleteOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.trash : Icons.delete_outline;

  static IconData get refresh =>
      PlatformUtils.isApple ? CupertinoIcons.arrow_clockwise : Icons.refresh;

  static IconData get close =>
      PlatformUtils.isApple ? CupertinoIcons.xmark : Icons.close;

  static IconData get check =>
      PlatformUtils.isApple ? CupertinoIcons.checkmark : Icons.check;

  static IconData get checkCircle =>
      PlatformUtils.isApple ? CupertinoIcons.checkmark_circle : Icons.check_circle;

  static IconData get checkCircleOutline =>
      PlatformUtils.isApple ? CupertinoIcons.checkmark_circle : Icons.check_circle_outline;

  static IconData get clear =>
      PlatformUtils.isApple ? CupertinoIcons.clear : Icons.clear;

  static IconData get copy =>
      PlatformUtils.isApple ? CupertinoIcons.doc_on_doc : Icons.copy;

  static IconData get download =>
      PlatformUtils.isApple ? CupertinoIcons.arrow_down_circle : Icons.download;

  static IconData get upload =>
      PlatformUtils.isApple ? CupertinoIcons.arrow_up_circle : Icons.upload;

  static IconData get share =>
      PlatformUtils.isApple ? CupertinoIcons.share : Icons.share;

  // Navigation indicators
  static IconData get chevronRight =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_right : Icons.chevron_right;

  static IconData get chevronLeft =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_left : Icons.chevron_left;

  static IconData get chevronDown =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_down : Icons.keyboard_arrow_down;

  static IconData get chevronUp =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_up : Icons.keyboard_arrow_up;

  static IconData get arrowBack =>
      PlatformUtils.isApple ? CupertinoIcons.back : Icons.arrow_back;

  static IconData get arrowForward =>
      PlatformUtils.isApple ? CupertinoIcons.forward : Icons.arrow_forward;

  // Communication
  static IconData get phone =>
      PlatformUtils.isApple ? CupertinoIcons.phone : Icons.phone;

  static IconData get phoneOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.phone : Icons.phone_outlined;

  static IconData get message =>
      PlatformUtils.isApple ? CupertinoIcons.bubble_left : Icons.message;

  static IconData get messageOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.bubble_left : Icons.message_outlined;

  static IconData get email =>
      PlatformUtils.isApple ? CupertinoIcons.mail : Icons.email;

  static IconData get emailOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.mail : Icons.email_outlined;

  // People
  static IconData get person =>
      PlatformUtils.isApple ? CupertinoIcons.person : Icons.person;

  static IconData get personOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.person : Icons.person_outline;

  static IconData get people =>
      PlatformUtils.isApple ? CupertinoIcons.person_2 : Icons.people;

  static IconData get peopleOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.person_2 : Icons.people_outline;

  static IconData get groups =>
      PlatformUtils.isApple ? CupertinoIcons.person_3 : Icons.groups;

  static IconData get groupsOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.person_3 : Icons.groups_outlined;

  static IconData get personAdd =>
      PlatformUtils.isApple ? CupertinoIcons.person_add : Icons.person_add;

  static IconData get addCircleOutline =>
      PlatformUtils.isApple ? CupertinoIcons.plus_circle : Icons.add_circle_outline;

  static IconData get removeCircle =>
      PlatformUtils.isApple ? CupertinoIcons.minus_circle_fill : Icons.remove_circle;

  static IconData get removeCircleOutline =>
      PlatformUtils.isApple ? CupertinoIcons.minus_circle : Icons.remove_circle_outline;

  // Status
  static IconData get info =>
      PlatformUtils.isApple ? CupertinoIcons.info : Icons.info;

  static IconData get infoOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.info : Icons.info_outline;

  static IconData get warning =>
      PlatformUtils.isApple ? CupertinoIcons.exclamationmark_triangle : Icons.warning;

  static IconData get error =>
      PlatformUtils.isApple ? CupertinoIcons.exclamationmark_circle : Icons.error;

  static IconData get help =>
      PlatformUtils.isApple ? CupertinoIcons.question_circle : Icons.help;

  static IconData get notifications =>
      PlatformUtils.isApple ? CupertinoIcons.bell : Icons.notifications;

  static IconData get notificationsOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.bell : Icons.notifications_none;

  // Visibility
  static IconData get visibility =>
      PlatformUtils.isApple ? CupertinoIcons.eye : Icons.visibility;

  static IconData get visibilityOff =>
      PlatformUtils.isApple ? CupertinoIcons.eye_slash : Icons.visibility_off;

  // Location
  static IconData get location =>
      PlatformUtils.isApple ? CupertinoIcons.location : Icons.location_on;

  static IconData get locationOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.location : Icons.location_on_outlined;

  static IconData get myLocation =>
      PlatformUtils.isApple ? CupertinoIcons.location_fill : Icons.my_location;

  static IconData get directions =>
      PlatformUtils.isApple ? CupertinoIcons.map : Icons.directions;

  // Time
  static IconData get history =>
      PlatformUtils.isApple ? CupertinoIcons.clock : Icons.history;

  static IconData get schedule =>
      PlatformUtils.isApple ? CupertinoIcons.clock : Icons.schedule;

  static IconData get calendar =>
      PlatformUtils.isApple ? CupertinoIcons.calendar : Icons.calendar_today;

  static IconData get calendarToday =>
      PlatformUtils.isApple ? CupertinoIcons.calendar_today : Icons.calendar_today;

  // Misc
  static IconData get star =>
      PlatformUtils.isApple ? CupertinoIcons.star : Icons.star;

  static IconData get starOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.star : Icons.star_outline;

  static IconData get filter =>
      PlatformUtils.isApple ? CupertinoIcons.slider_horizontal_3 : Icons.filter_list;

  static IconData get sort =>
      PlatformUtils.isApple ? CupertinoIcons.sort_down : Icons.sort;

  static IconData get menu =>
      PlatformUtils.isApple ? CupertinoIcons.ellipsis : Icons.more_vert;

  static IconData get menuHorizontal =>
      PlatformUtils.isApple ? CupertinoIcons.ellipsis : Icons.more_horiz;

  static IconData get expandMore =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_down : Icons.expand_more;

  static IconData get expandLess =>
      PlatformUtils.isApple ? CupertinoIcons.chevron_up : Icons.expand_less;

  // App-specific
  static IconData get vote =>
      PlatformUtils.isApple ? CupertinoIcons.hand_thumbsup : Icons.how_to_vote;

  static IconData get admin =>
      PlatformUtils.isApple ? CupertinoIcons.person_badge_plus : Icons.admin_panel_settings;

  static IconData get adminOutlined =>
      PlatformUtils.isApple ? CupertinoIcons.person_badge_plus : Icons.admin_panel_settings_outlined;

  static IconData get door =>
      PlatformUtils.isApple ? CupertinoIcons.home : Icons.door_front_door;

  static IconData get logout =>
      PlatformUtils.isApple ? CupertinoIcons.square_arrow_right : Icons.logout;

  static IconData get cloudOff =>
      PlatformUtils.isApple ? CupertinoIcons.cloud : Icons.cloud_off;

  static IconData get cloudSync =>
      PlatformUtils.isApple ? CupertinoIcons.arrow_2_circlepath_circle : Icons.cloud_sync;

  static IconData get cloudDownload =>
      PlatformUtils.isApple ? CupertinoIcons.cloud_download : Icons.cloud_download;

  static IconData get flash =>
      PlatformUtils.isApple ? CupertinoIcons.bolt : Icons.flash_on;

  static IconData get lock =>
      PlatformUtils.isApple ? CupertinoIcons.lock : Icons.lock;

  static IconData get landscape =>
      PlatformUtils.isApple ? CupertinoIcons.square_grid_2x2 : Icons.landscape;

  static IconData get checklist =>
      PlatformUtils.isApple ? CupertinoIcons.checkmark_rectangle : Icons.checklist;

  static IconData get description =>
      PlatformUtils.isApple ? CupertinoIcons.doc_text : Icons.description;

  static IconData get label =>
      PlatformUtils.isApple ? CupertinoIcons.tag : Icons.label;

  static IconData get undo =>
      PlatformUtils.isApple ? CupertinoIcons.arrow_uturn_left : Icons.undo;

  static IconData get doneAll =>
      PlatformUtils.isApple ? CupertinoIcons.checkmark_seal : Icons.done_all;

  static IconData get touch =>
      PlatformUtils.isApple ? CupertinoIcons.hand_point_right : Icons.touch_app;

  static IconData get privacy =>
      PlatformUtils.isApple ? CupertinoIcons.shield : Icons.privacy_tip;

  static IconData get gavel =>
      PlatformUtils.isApple ? CupertinoIcons.doc_plaintext : Icons.gavel;

  static IconData get hourglass =>
      PlatformUtils.isApple ? CupertinoIcons.hourglass : Icons.hourglass_empty;
}
