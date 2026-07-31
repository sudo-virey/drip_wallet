import 'package:flutter/material.dart';

/// Convierte nombres de iconos (string) a IconData de Material Icons
IconData stringToIconData(String iconName) {
  switch (iconName) {
    case 'restaurant':
      return Icons.restaurant;
    case 'directions_car':
      return Icons.directions_car;
    case 'receipt':
      return Icons.receipt;
    case 'shopping_bag':
      return Icons.shopping_bag;
    case 'home':
      return Icons.home;
    case 'sentiment_satisfied':
      return Icons.sentiment_satisfied;
    case 'attach_money':
      return Icons.attach_money;
    case 'work':
      return Icons.work;
    case 'trending_up':
      return Icons.trending_up;
    case 'card_giftcard':
      return Icons.card_giftcard;
    case 'favorite':
      return Icons.favorite;
    case 'volunteer_activism':
      return Icons.volunteer_activism;
    case 'more_horiz':
      return Icons.more_horiz;
    case 'shopping_cart':
      return Icons.shopping_cart;
    case 'local_hospital':
      return Icons.local_hospital;
    case 'school':
      return Icons.school;
    case 'beauty':
      return Icons.brush;
    case 'fitness_center':
      return Icons.fitness_center;
    case 'videogame_asset':
      return Icons.videogame_asset;
    case 'notifications_none':
      return Icons.notifications_none;
    case 'settings_outlined':
      return Icons.settings_outlined;
    case 'edit':
      return Icons.edit;
    case 'delete':
      return Icons.delete;
    case 'inbox':
      return Icons.inbox;
    case 'calendar_today':
      return Icons.calendar_today;
    case 'chevron_left':
      return Icons.chevron_left;
    case 'chevron_right':
      return Icons.chevron_right;
    case 'error':
      return Icons.error;
    case 'account_circle':
      return Icons.account_circle;
    case 'home_filled':
      return Icons.home;
    default:
      return Icons.category;
  }
}
