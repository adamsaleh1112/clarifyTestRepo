import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Switch, Alert, Platform } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { getTheme } from '@/utils/theme';

export default function SettingsScreen() {
  const router = useRouter();

  const [darkMode, setDarkMode] = useState(false);
  const [textSize, setTextSize] = useState<'small' | 'medium' | 'large'>('medium');
  const [notifications, setNotifications] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const stored = await AsyncStorage.getItem('settings');
        if (stored) {
          const parsed = JSON.parse(stored);
          if (typeof parsed.darkMode === 'boolean') setDarkMode(parsed.darkMode);
          if (parsed.textSize === 'small' || parsed.textSize === 'medium' || parsed.textSize === 'large') setTextSize(parsed.textSize);
          if (typeof parsed.notifications === 'boolean') setNotifications(parsed.notifications);
        }
      } catch (e) {
        console.warn('Failed to load settings', e);
      }
    })();
  }, []);

  const persist = async (next: Partial<{ darkMode: boolean; textSize: 'small' | 'medium' | 'large'; notifications: boolean }>) => {
    try {
      const currentRaw = await AsyncStorage.getItem('settings');
      const current = currentRaw ? JSON.parse(currentRaw) : {};
      const merged = { ...current, ...next };
      await AsyncStorage.setItem('settings', JSON.stringify(merged));
    } catch (e) {
      console.warn('Failed to save settings', e);
    }
  };

  const toggleDarkMode = (value: boolean) => {
    setDarkMode(value);
    persist({ darkMode: value });
  };

  const setSize = (size: 'small' | 'medium' | 'large') => {
    setTextSize(size);
    persist({ textSize: size });
  };

  const toggleNotifications = (value: boolean) => {
    setNotifications(value);
    persist({ notifications: value });
  };

  const clearCache = async () => {
    try {
      // In the future, clear more caches as needed; for now we reset stored articles as an example prompt
      Alert.alert(
        'Clear Cache',
        'This will clear stored articles and settings. Continue?',
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Clear',
            style: 'destructive',
            onPress: async () => {
              await AsyncStorage.removeItem('articles');
              // Keep settings screen state but clear persisted settings as demonstration is optional
              Alert.alert('Cleared', 'Local cache cleared.');
            },
          },
        ]
      );
    } catch (e) {
      Alert.alert('Error', 'Failed to clear cache.');
    }
  };

  const colors = getTheme(darkMode);

  return (
    <View style={[styles.container, { backgroundColor: colors.bg }]}>
      <View style={styles.header}>
        <TouchableOpacity style={[styles.backButton, { backgroundColor: colors.chip }]} onPress={() => router.back()}>
          <Ionicons name="chevron-back" size={20} color={colors.icon} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.text }]}>Settings</Text>
        <View style={{ width: 40 }} />
      </View>

      <View style={styles.list}>
        <View style={styles.itemRow}>
          <View style={styles.itemLeft}>
            <Ionicons name="moon-outline" size={18} color={colors.icon} style={styles.itemIcon} />
            <Text style={[styles.itemTitle, { color: colors.text }]}>Dark Mode</Text>
          </View>
          <Switch value={darkMode} onValueChange={toggleDarkMode} />
        </View>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <View style={styles.itemRow}>
          <View style={styles.itemLeft}>
            <Ionicons name="text-outline" size={18} color={colors.icon} style={styles.itemIcon} />
            <Text style={[styles.itemTitle, { color: colors.text }]}>Text Size</Text>
          </View>
          <View style={[styles.segmented, { backgroundColor: colors.chip }]}>
            {(['small', 'medium', 'large'] as const).map((s) => (
              <TouchableOpacity
                key={s}
                style={[styles.segment, textSize === s && { backgroundColor: colors.surface }]}
                onPress={() => setSize(s)}
              >
                <Text style={[styles.segmentText, { color: colors.text }, textSize === s && { fontWeight: '600' }]}>
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <View style={styles.itemRow}>
          <View style={styles.itemLeft}>
            <Ionicons name="notifications-outline" size={18} color={colors.icon} style={styles.itemIcon} />
            <Text style={[styles.itemTitle, { color: colors.text }]}>Notifications</Text>
          </View>
          <Switch value={notifications} onValueChange={toggleNotifications} />
        </View>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <TouchableOpacity style={styles.itemRow} onPress={clearCache}>
          <View style={styles.itemLeft}>
            <Ionicons name="trash-outline" size={18} color="#c0392b" style={styles.itemIcon} />
            <Text style={[styles.itemTitle, { color: '#c0392b' }]}>Clear Cache</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        </TouchableOpacity>

        <View style={[styles.divider, { backgroundColor: colors.border }]} />

        <TouchableOpacity
          style={styles.itemRow}
          onPress={() => Alert.alert('About', 'Clarify App v1.0.0')}
        >
          <View style={styles.itemLeft}>
            <Ionicons name="information-circle-outline" size={18} color={colors.icon} style={styles.itemIcon} />
            <Text style={[styles.itemTitle, { color: colors.text }]}>About</Text>
          </View>
          <Ionicons name="chevron-forward" size={18} color={colors.textMuted} />
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f6f4f1',
  },
  header: {
    paddingTop: 70,
    paddingHorizontal: 24,
    paddingBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  backButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#edebe8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1a1a1a',
    fontFamily: Platform.OS === 'ios' ? 'Georgia-Bold' : 'serif',
  },
  list: {
    paddingHorizontal: 16,
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
  },
  itemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  itemIcon: {
    marginRight: 10,
  },
  itemTitle: {
    fontSize: 16,
    color: '#1a1a1a',
  },
  itemNote: {
    color: '#777',
    fontSize: 12,
    marginTop: -8,
    marginBottom: 8,
    paddingLeft: 28,
  },
  divider: {
    height: 1,
    backgroundColor: '#e8e6e3',
  },
  segmented: {
    backgroundColor: '#edebe8',
    borderRadius: 8,
    flexDirection: 'row',
    overflow: 'hidden',
  },
  segment: {
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  segmentActive: {
    backgroundColor: '#faf9f7',
  },
  segmentText: {
    color: '#333',
    fontSize: 14,
  },
  segmentTextActive: {
    fontWeight: '600',
    color: '#000',
  },
});
