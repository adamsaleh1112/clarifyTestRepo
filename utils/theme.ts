export interface ThemeColors {
  bg: string;
  surface: string;
  surface2: string;
  chip: string;
  border: string;
  text: string;
  textMuted: string;
  icon: string;
}

export const lightTheme: ThemeColors = {
  bg: '#f6f4f1',
  surface: '#faf9f7',
  surface2: '#edebe8',
  chip: '#edebe8',
  border: '#e8e6e3',
  text: '#1a1a1a',
  textMuted: '#666',
  icon: '#1a1918',
};

export const darkTheme: ThemeColors = {
  bg: '#111213',
  surface: '#1a1b1c',
  surface2: '#222325',
  chip: '#2a2b2e',
  border: '#2f3033',
  text: '#e8e9eb',
  textMuted: '#a9abb0',
  icon: '#e8e9eb',
};

export const getTheme = (isDark: boolean): ThemeColors => {
  return isDark ? darkTheme : lightTheme;
};
