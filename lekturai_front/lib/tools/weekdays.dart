String getFullWeekdayName(String shortcut) {
  switch (shortcut.toLowerCase()) {
    case 'pn':
      return 'Poniedziałek';
    case 'wt':
      return 'Wtorek';
    case 'śr':
      return 'Środa';
    case 'cz':
      return 'Czwartek';
    case 'pt':
      return 'Piątek';
    case 'sb':
      return 'Sobota';
    case 'nd':
      return 'Niedziela';
    default:
      return 'Nieznany dzień';
  }
}