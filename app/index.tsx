import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Clipboard from 'expo-clipboard';
import { StatusBar } from 'expo-status-bar';
import React, { useEffect, useState } from 'react';
import { Alert, Dimensions, Image, Modal, ScrollView, StyleSheet, Text, TouchableOpacity, View } from 'react-native';

interface Article {
  id: string;
  title: string;
  url: string;
  content: string;
  date: string;
  imageUrl?: string;
}

const { width } = Dimensions.get('window');
const cardWidth = (width - 48) / 2;

export default function HomeScreen() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedArticle, setSelectedArticle] = useState<Article | null>(null);

  useEffect(() => {
    loadArticles();
  }, []);

  const loadArticles = async () => {
    try {
      const stored = await AsyncStorage.getItem('articles');
      if (stored) {
        setArticles(JSON.parse(stored));
      } else {
        // Add example article
        const exampleArticle: Article = {
          id: '1',
          title: 'NFL "Rivalries" Uniforms',
          url: 'https://example.com',
          content: `The league's other 24 teams will get their own "Rivalries" uniforms in future years, two additional divisions to be added to the rotation annually through the 2026 season.

"Rivalries will bring fresh energy to the field with each new uniform, while providing a platform to amplify the community and hometown pride that is rooted in each NFL fan," said Taryn Hutt, the NFL's vice president of club marketing, said in a statement.

The new "Rivalries" jerseys and associated gear and apparel will be available at nike.com, NFLshop.com, and fanatics.com starting Sept. 10.

The league will literally look quite different in 2025 as eight teams – the Bills, Browns, Steelers, Chargers, Commanders, Packers, Saints (a new helmet and a new/old jersey) and Buccaneers – previously revealed new throwback and/or alternate uniform looks earlier this summer.`,
          date: 'August 29, 2025',
          imageUrl: 'https://via.placeholder.com/300x200/4A90E2/FFFFFF?text=NFL+Uniforms'
        };
        setArticles([exampleArticle]);
        await AsyncStorage.setItem('articles', JSON.stringify([exampleArticle]));
      }
    } catch (error) {
      console.error('Error loading articles:', error);
    }
  };

  const extractArticleFromUrl = async (url: string) => {
    // Simple article extraction - in a real app you'd use a proper service
    try {
      const response = await fetch(url);
      const html = await response.text();
      
      // Basic title extraction
      const titleMatch = html.match(/<title>(.*?)<\/title>/i);
      const title = titleMatch ? titleMatch[1] : 'Untitled Article';
      
      // Basic content extraction (this is very simplified)
      const contentMatch = html.match(/<p>(.*?)<\/p>/gi);
      const content = contentMatch ? contentMatch.join('\n\n').replace(/<[^>]*>/g, '') : 'Content could not be extracted';
      
      const newArticle: Article = {
        id: Date.now().toString(),
        title: title.substring(0, 100),
        url,
        content,
        date: new Date().toLocaleDateString(),
      };

      const updatedArticles = [newArticle, ...articles];
      setArticles(updatedArticles);
      await AsyncStorage.setItem('articles', JSON.stringify(updatedArticles));
      
      return newArticle;
    } catch (error) {
      throw new Error('Failed to extract article content');
    }
  };

  const handleAddArticle = async () => {
    try {
      const clipboardContent = await Clipboard.getStringAsync();
      
      if (!clipboardContent || !clipboardContent.startsWith('http')) {
        Alert.alert('Error', 'Please copy a valid URL to your clipboard first');
        return;
      }

      setShowAddModal(false);
      const article = await extractArticleFromUrl(clipboardContent);
      setSelectedArticle(article);
    } catch (error) {
      Alert.alert('Error', 'Failed to extract article content');
    }
  };

  const renderArticleCard = (article: Article) => (
    <TouchableOpacity
      key={article.id}
      style={styles.articleCard}
      onPress={() => setSelectedArticle(article)}
    >
      {article.imageUrl && (
        <Image source={{ uri: article.imageUrl }} style={styles.articleImage} />
      )}
      <View style={styles.articleInfo}>
        <Text style={styles.articleTitle} numberOfLines={3}>
          {article.title}
        </Text>
        <Text style={styles.articleDate}>{article.date}</Text>
      </View>
    </TouchableOpacity>
  );

  const renderArticleReader = () => (
    <Modal visible={!!selectedArticle} animationType="slide">
      <View style={styles.readerContainer}>
        <View style={styles.readerHeader}>
          <TouchableOpacity onPress={() => setSelectedArticle(null)}>
            <Text style={styles.backButton}>← Back</Text>
          </TouchableOpacity>
        </View>
        
        {selectedArticle && (
          <ScrollView style={styles.readerContent} showsVerticalScrollIndicator={false}>
            <Text style={styles.readerTitle}>{selectedArticle.title}</Text>
            <Text style={styles.readerDate}>{selectedArticle.date}</Text>
            <Text style={styles.readerText}>{selectedArticle.content}</Text>
          </ScrollView>
        )}
      </View>
    </Modal>
  );

  const renderAddModal = () => (
    <Modal visible={showAddModal} transparent animationType="fade">
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          <TouchableOpacity
            style={styles.pasteButton}
            onPress={handleAddArticle}
          >
            <Text style={styles.pasteButtonText}>Paste Article URL</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.cancelButton}
            onPress={() => setShowAddModal(false)}
          >
            <Text style={styles.cancelButtonText}>Cancel</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Your articles</Text>
      </View>

      <ScrollView style={styles.articlesContainer} showsVerticalScrollIndicator={false}>
        <View style={styles.articlesGrid}>
          {articles.map(renderArticleCard)}
        </View>
      </ScrollView>

      <TouchableOpacity
        style={styles.addButton}
        onPress={() => setShowAddModal(true)}
      >
        <Text style={styles.addButtonText}>+</Text>
      </TouchableOpacity>

      {renderAddModal()}
      {renderArticleReader()}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    paddingTop: 60,
    paddingHorizontal: 24,
    paddingBottom: 20,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1a1a1a',
  },
  articlesContainer: {
    flex: 1,
    paddingHorizontal: 16,
  },
  articlesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  articleCard: {
    width: cardWidth,
    backgroundColor: '#ffffff',
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  articleImage: {
    width: '100%',
    height: 120,
    borderTopLeftRadius: 12,
    borderTopRightRadius: 12,
  },
  articleInfo: {
    padding: 12,
  },
  articleTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1a1a1a',
    lineHeight: 20,
    marginBottom: 8,
  },
  articleDate: {
    fontSize: 12,
    color: '#666',
  },
  addButton: {
    position: 'absolute',
    bottom: 30,
    right: 30,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#007AFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
  },
  addButtonText: {
    fontSize: 24,
    color: '#ffffff',
    fontWeight: '300',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(248, 249, 250, 0.95)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    alignItems: 'center',
  },
  pasteButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 12,
    marginBottom: 16,
  },
  pasteButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  cancelButton: {
    paddingHorizontal: 32,
    paddingVertical: 16,
  },
  cancelButtonText: {
    color: '#666',
    fontSize: 16,
  },
  readerContainer: {
    flex: 1,
    backgroundColor: '#ffffff',
  },
  readerHeader: {
    paddingTop: 60,
    paddingHorizontal: 24,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  backButton: {
    fontSize: 16,
    color: '#007AFF',
  },
  readerContent: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 24,
  },
  readerTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1a1a1a',
    lineHeight: 32,
    marginBottom: 8,
  },
  readerDate: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
  },
  readerText: {
    fontSize: 16,
    lineHeight: 24,
    color: '#333',
    paddingBottom: 40,
  },
});
