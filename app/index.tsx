import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { BlurView } from 'expo-blur';
import * as Clipboard from 'expo-clipboard';
import * as Haptics from 'expo-haptics';
import * as DocumentPicker from 'expo-document-picker';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Animated, Dimensions, Image, Modal, Platform, RefreshControl, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useFocusEffect } from '@react-navigation/native';
import { getTheme } from '@/utils/theme';

interface Article {
  id: string;
  title: string;
  content: string;
  date: string;
  imageUrl?: string;
  inlineImages?: string[];
  bookmarked?: boolean;
  deleteAnimation?: any;
  url?: string;
}

interface ContentBlock {
  type: 'heading' | 'paragraph' | 'quote' | 'caption' | 'list-item' | 'image';
  text: string;
  imageUrl?: string;
  position?: number;
}

const { width } = Dimensions.get('window');
const cardWidth = (width - 48) / 2;

export default function HomeScreen() {
  const router = useRouter();
  const [articles, setArticles] = useState<Article[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedArticle, setSelectedArticle] = useState<Article | null>(null);
  const [deleteMode, setDeleteMode] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [deletingArticles, setDeletingArticles] = useState<Set<string>>(new Set());
  const [isPenExpanded, setIsPenExpanded] = useState(false);
  const [showBookmarkedOnly, setShowBookmarkedOnly] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const rotateAnim = React.useRef(new Animated.Value(0)).current;
  const scaleAnim = React.useRef(new Animated.Value(1)).current;
  const deleteButtonsScale = React.useRef(new Animated.Value(0)).current;
  const modalOpacity = React.useRef(new Animated.Value(0)).current;
  const contentOpacity = React.useRef(new Animated.Value(0)).current;
  const leftButtonScale = React.useRef(new Animated.Value(1)).current;
  const rightButtonScale = React.useRef(new Animated.Value(1)).current;

  useEffect(() => {
    loadArticles();
    loadSettings();
  }, []);

  useFocusEffect(
    React.useCallback(() => {
      // Reload settings whenever the screen is focused (e.g., after returning from Settings)
      loadSettings();
      return () => {};
    }, [])
  );

  const onRefresh = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await loadArticles(true);
  };

  const loadSettings = async () => {
    try {
      const stored = await AsyncStorage.getItem('settings');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (typeof parsed.darkMode === 'boolean') {
          setDarkMode(parsed.darkMode);
        }
      }
    } catch (e) {
      // ignore
    }
  };

  const filteredArticles = articles.filter(article => {
    const matchesSearch = article.title.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesBookmarkFilter = showBookmarkedOnly ? article.bookmarked : true;
    return matchesSearch && matchesBookmarkFilter;
  });

  const toggleSearch = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setShowSearch(!showSearch);
    if (showSearch) {
      setSearchQuery('');
    }
  };

  const handleOpenSettings = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    router.push('/settings');
  };

  const loadArticles = async (showRefreshFeedback = false) => {
    try {
      if (showRefreshFeedback) {
        setRefreshing(true);
      }
      
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
      if (showRefreshFeedback) {
        Alert.alert('Error', 'Failed to refresh articles');
      }
    } finally {
      if (showRefreshFeedback) {
        setRefreshing(false);
      }
    }
  };

  const extractArticleFromUrl = async (url: string) => {
    try {
      // Validate URL format
      if (!url.match(/^https?:\/\/.+/)) {
        throw new Error('Please enter a valid URL starting with http:// or https://');
      }

      const response = await fetch(url);
      
      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Article not found. Please check the URL and try again.');
        } else if (response.status === 403) {
          throw new Error('Access denied. This website may not allow article extraction.');
        } else if (response.status >= 500) {
          throw new Error('Server error. Please try again later.');
        } else {
          throw new Error(`Failed to load article (Error ${response.status})`);
        }
      }
      
      const html = await response.text();
      
      if (!html || html.length < 100) {
        throw new Error('The webpage appears to be empty or too short to extract content.');
      }
      
      let title = 'Untitled Article';
      let content = 'Content could not be extracted';
      
      // Enhanced article content extraction
      // Extract title from HTML
      const titleMatch = html.match(/<title>(.*?)<\/title>/i);
      if (titleMatch) {
        title = titleMatch[1]
          .replace(/&[^;]+;/g, '')
          .replace(/\s+/g, ' ')
          .trim();
      }
      
      // Extract main image from article
      let imageUrl = '';
      
      // Try Open Graph image first (most reliable for news sites)
      const ogImageMatch = html.match(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i);
      if (ogImageMatch) {
        imageUrl = ogImageMatch[1];
      }
      
      // Fallback to Twitter Card image
      if (!imageUrl) {
        const twitterImageMatch = html.match(/<meta[^>]*name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i);
        if (twitterImageMatch) {
          imageUrl = twitterImageMatch[1];
        }
      }
      
      // Fallback to article images
      if (!imageUrl) {
        const articleImageSelectors = [
          /<article[^>]*>[\s\S]*?<img[^>]*src=["']([^"']+)["'][^>]*>/i,
          /<main[^>]*>[\s\S]*?<img[^>]*src=["']([^"']+)["'][^>]*>/i,
          /<div[^>]*class=["'][^"']*(?:hero|featured|main)[^"']*["'][^>]*>[\s\S]*?<img[^>]*src=["']([^"']+)["'][^>]*>/i
        ];
        
        for (const selector of articleImageSelectors) {
          const match = html.match(selector);
          if (match && match[1]) {
            imageUrl = match[1];
            break;
          }
        }
      }
      
      // Ensure image URL is absolute
      if (imageUrl && !imageUrl.startsWith('http')) {
        try {
          const baseUrl = new URL(url);
          if (imageUrl.startsWith('//')) {
            imageUrl = baseUrl.protocol + imageUrl;
          } else if (imageUrl.startsWith('/')) {
            imageUrl = baseUrl.origin + imageUrl;
          } else {
            imageUrl = baseUrl.origin + '/' + imageUrl;
          }
        } catch (e) {
          console.log('Error resolving image URL:', e);
          imageUrl = '';
        }
      }
      
      // Enhanced content extraction with better selectors and priority
      const articleSelectors = [
        // High priority - semantic article tags
        /<article[^>]*>([\s\S]*?)<\/article>/gi,
        /<main[^>]*>([\s\S]*?)<\/main>/gi,
        
        // Medium priority - common content containers
        /<div[^>]*class=["'][^"']*(?:post-content|article-content|entry-content|story-body|article-body)[^"']*["'][^>]*>([\s\S]*?)<\/div>/gi,
        /<div[^>]*class=["'][^"']*(?:content|article|post|entry|story)[^"']*["'][^>]*>([\s\S]*?)<\/div>/gi,
        /<section[^>]*class=["'][^"']*(?:content|article|post|entry|story)[^"']*["'][^>]*>([\s\S]*?)<\/section>/gi,
        
        // Lower priority - ID-based selectors
        /<div[^>]*id=["'][^"']*(?:content|article|post|entry|story)[^"']*["'][^>]*>([\s\S]*?)<\/div>/gi,
        
        // News-specific selectors
        /<div[^>]*class=["'][^"']*(?:article-text|story-text|post-body|entry-body)[^"']*["'][^>]*>([\s\S]*?)<\/div>/gi,
        /<div[^>]*data-module=["']ArticleBody["'][^>]*>([\s\S]*?)<\/div>/gi
      ];
      
      // Smart content extraction with structured text parsing and image positioning
      const extractStructuredContent = (htmlContent: string): { blocks: ContentBlock[], images: string[] } => {
        const extractedImages: string[] = [];
        
        // Remove unwanted elements first but preserve structure for positioning
        let cleanHtml = htmlContent
          .replace(/<script[\s\S]*?<\/script>/gi, '')
          .replace(/<style[\s\S]*?<\/style>/gi, '')
          .replace(/<nav[\s\S]*?<\/nav>/gi, '')
          .replace(/<header[\s\S]*?<\/header>/gi, '')
          .replace(/<footer[\s\S]*?<\/footer>/gi, '')
          .replace(/<aside[\s\S]*?<\/aside>/gi, '')
          .replace(/<form[\s\S]*?<\/form>/gi, '')
          .replace(/<iframe[\s\S]*?<\/iframe>/gi, '')
          .replace(/<div[^>]*class=["'][^"']*(?:ad|advertisement|ads|promo|social|share|sidebar|menu|navigation|related|recommended|newsletter|subscribe)[^"']*["'][^>]*>[\s\S]*?<\/div>/gi, '')
          .replace(/<!--[\s\S]*?-->/g, '');
        
        // Helper function to resolve relative URLs
        const resolveImageUrl = (imgSrc: string, baseUrl: string): string => {
          if (!imgSrc || imgSrc.startsWith('http') || imgSrc.startsWith('data:')) {
            return imgSrc;
          }
          try {
            const base = new URL(baseUrl);
            if (imgSrc.startsWith('//')) {
              return base.protocol + imgSrc;
            } else if (imgSrc.startsWith('/')) {
              return base.origin + imgSrc;
            } else {
              return base.origin + '/' + imgSrc;
            }
          } catch (e) {
            return imgSrc;
          }
        };
        
        // Parse content in document order to maintain positioning
        const contentElements: ContentBlock[] = [];
        
        // Extract all content elements with their positions
        const allElements = cleanHtml.match(/<(h[1-6]|p|blockquote|figure|img|li)[^>]*>[\s\S]*?<\/\1>|<img[^>]*\/?>/gi) || [];
        
        allElements.forEach((element, index) => {
          const tagMatch = element.match(/<(\w+)/);
          const tag = tagMatch ? tagMatch[1].toLowerCase() : '';
          
          switch (tag) {
            case 'h1':
            case 'h2':
            case 'h3':
            case 'h4':
            case 'h5':
            case 'h6':
              const headingText = element.replace(/<[^>]*>/g, '').replace(/&[^;]+;/g, '').trim();
              if (headingText.length > 5) {
                contentElements.push({ type: 'heading', text: headingText, position: index });
              }
              break;
              
            case 'p':
              let paraText = element.replace(/<[^>]*>/g, ' ').replace(/&[^;]+;/g, '').replace(/\s+/g, ' ').trim();
              if (paraText.length > 30) {
                const captionKeywords = /^(photo|image|picture|caption|credit|getty|reuters|ap|afp):/i;
                const isShortAndImageRelated = paraText.length < 150 && captionKeywords.test(paraText);
                
                if (isShortAndImageRelated) {
                  contentElements.push({ type: 'caption', text: paraText, position: index });
                } else {
                  contentElements.push({ type: 'paragraph', text: paraText, position: index });
                }
              }
              break;
              
            case 'blockquote':
              const quoteText = element.replace(/<[^>]*>/g, '').replace(/&[^;]+;/g, '').trim();
              if (quoteText.length > 20) {
                contentElements.push({ type: 'quote', text: quoteText, position: index });
              }
              break;
              
            case 'figure':
              // Extract image from figure
              const figImgMatch = element.match(/<img[^>]*src=["']([^"']+)["'][^>]*>/i);
              const figCaptionMatch = element.match(/<figcaption[^>]*>([\s\S]*?)<\/figcaption>/i);
              
              if (figImgMatch) {
                const imgUrl = resolveImageUrl(figImgMatch[1], url);
                extractedImages.push(imgUrl);
                contentElements.push({ type: 'image', text: '', imageUrl: imgUrl, position: index });
                
                if (figCaptionMatch) {
                  const captionText = figCaptionMatch[1].replace(/<[^>]*>/g, '').replace(/&[^;]+;/g, '').trim();
                  if (captionText.length > 10) {
                    contentElements.push({ type: 'caption', text: captionText, position: index + 0.1 });
                  }
                }
              }
              break;
              
            case 'img':
              const imgMatch = element.match(/src=["']([^"']+)["']/i);
              const altMatch = element.match(/alt=["']([^"']*)["']/i);
              
              if (imgMatch) {
                const imgUrl = resolveImageUrl(imgMatch[1], url);
                const altText = altMatch ? altMatch[1] : '';
                
                // Filter out small/icon images
                const widthMatch = element.match(/width=["']?(\d+)["']?/i);
                const heightMatch = element.match(/height=["']?(\d+)["']?/i);
                const width = widthMatch ? parseInt(widthMatch[1]) : 0;
                const height = heightMatch ? parseInt(heightMatch[1]) : 0;
                
                // Only include substantial images (not icons/buttons)
                if ((width === 0 || width > 100) && (height === 0 || height > 100)) {
                  extractedImages.push(imgUrl);
                  contentElements.push({ 
                    type: 'image', 
                    text: altText || '', 
                    imageUrl: imgUrl, 
                    position: index 
                  });
                }
              }
              break;
              
            case 'li':
              const listText = element.replace(/<[^>]*>/g, '').replace(/&[^;]+;/g, '').trim();
              if (listText.length > 15) {
                contentElements.push({ type: 'list-item', text: listText, position: index });
              }
              break;
          }
        });
        
        // Sort by position to maintain document order
        const sortedElements = contentElements.sort((a: ContentBlock, b: ContentBlock) => (a.position || 0) - (b.position || 0));
        return { blocks: sortedElements, images: extractedImages };
      };
      
      // Extract different content types with their structure preserved
      let extractedInlineImages: string[] = [];
      
      for (const selector of articleSelectors) {
        const matches = html.match(selector);
        if (matches && matches.length > 0) {
          for (const match of matches) {
            const { blocks: structuredBlocks, images: inlineImages } = extractStructuredContent(match);
            
            if (structuredBlocks.length >= 3) {
              // Store the extracted images
              extractedInlineImages = inlineImages;
              
              // Format the structured content with proper spacing, formatting, and image placeholders
              const formattedContent = structuredBlocks.map(block => {
                switch (block.type) {
                  case 'heading':
                    return `\n\n## ${block.text}\n`;
                  case 'quote':
                    return `\n> ${block.text}\n`;
                  case 'caption':
                    return `\n*${block.text}*\n`;
                  case 'list-item':
                    return `• ${block.text}`;
                  case 'image':
                    if (block.imageUrl) {
                      const imageIndex = inlineImages.indexOf(block.imageUrl);
                      const altText = block.text ? ` - ${block.text}` : '';
                      return `\n[IMAGE_${imageIndex}]${altText}\n`;
                    }
                    return '';
                  case 'paragraph':
                  default:
                    return `\n${block.text}\n`;
                }
              }).join('').replace(/\n{3,}/g, '\n\n').trim();
              
              if (formattedContent.length > 300) {
                content = formattedContent;
                break;
              }
            }
          }
          
          if (content !== 'Content could not be extracted') {
            break;
          }
        }
      }
      
      // Enhanced fallback with basic paragraph detection
      if (content === 'Content could not be extracted') {
        const paragraphs = html.match(/<p[^>]*>([\s\S]*?)<\/p>/gi);
        if (paragraphs && paragraphs.length > 0) {
          const processedParagraphs: string[] = [];
          
          paragraphs.forEach((p: string) => {
            let text = p
              .replace(/<[^>]*>/g, ' ')
              .replace(/&nbsp;/g, ' ')
              .replace(/&amp;/g, '&')
              .replace(/&lt;/g, '<')
              .replace(/&gt;/g, '>')
              .replace(/&quot;/g, '"')
              .replace(/&#39;/g, "'")
              .replace(/&mdash;/g, '—')
              .replace(/&ndash;/g, '–')
              .replace(/&[^;]+;/g, '')
              .replace(/\s+/g, ' ')
              .trim();
            
            if (text.length > 40 && 
                !text.match(/^(advertisement|ad|subscribe|follow|share|click|read more|continue reading|related articles|tags:|categories:|posted by|published|updated|copyright|all rights reserved)$/i) &&
                !text.match(/^[\d\s\/:-]+$/) &&
                text.split(' ').length >= 8) {
              
              // Detect captions vs regular paragraphs
              const captionKeywords = /^(photo|image|picture|caption|credit|getty|reuters|ap|afp):/i;
              if (text.length < 150 && captionKeywords.test(text)) {
                processedParagraphs.push(`*${text}*`);
              } else {
                processedParagraphs.push(text);
              }
            }
          });
          
          if (processedParagraphs.length >= 3) {
            content = processedParagraphs.slice(0, 15).join('\n\n');
          }
        }
      }
      
      // Enhanced content validation
      if (title === 'Untitled Article' && content === 'Content could not be extracted') {
        throw new Error('Unable to extract article content. This website may not be supported.');
      }
      
      if (content.length < 100) {
        throw new Error('Article content is too short. Please try a different URL.');
      }
      
      // Check for content quality
      const sentences = content.split(/[.!?]+/).filter(s => s.trim().length > 5);
      if (sentences.length < 2) {
        throw new Error('Article content appears incomplete. Please try a different URL.');
      }
      
      // Remove common prefixes and suffixes that might indicate poor extraction
      content = content
        .replace(/^(By\s+[^\n]+\n|Published\s+[^\n]+\n|Updated\s+[^\n]+\n)/i, '')
        .replace(/(Subscribe to our newsletter|Follow us on|Share this article|Related articles?).*$/is, '')
        .trim();

      const newArticle: Article = {
        id: Date.now().toString(),
        title: title.substring(0, 150),
        url,
        content: content.substring(0, 15000), // Increased content length limit
        date: new Date().toLocaleDateString(),
        imageUrl: imageUrl || undefined,
        inlineImages: extractedInlineImages.length > 0 ? extractedInlineImages : undefined,
      };

      const updatedArticles = [newArticle, ...articles];
      setArticles(updatedArticles);
      await AsyncStorage.setItem('articles', JSON.stringify(updatedArticles));
      
      return newArticle;
    } catch (error) {
      console.error('Article extraction error:', error);
      
      // Re-throw with user-friendly message if it's already a user-friendly error
      if (error instanceof Error && error.message.includes('Please') || error instanceof Error && error.message.includes('Unable to') || error instanceof Error && error.message.includes('not found') || error instanceof Error && error.message.includes('Access denied') || error instanceof Error && error.message.includes('Server error') || error instanceof Error && error.message.includes('too short')) {
        throw error;
      }
      
      // Network-related errors
      if (error instanceof TypeError && error.message.includes('fetch')) {
        throw new Error('Network error. Please check your internet connection and try again.');
      }
      
      // Generic fallback
      throw new Error('Failed to extract article content. Please try a different URL.');
    }
  };

  const handleAddButtonPress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    
    if (showAddModal) {
      // Close modal - rotate back to +
      Animated.parallel([
        Animated.timing(rotateAnim, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 1,
          useNativeDriver: true,
          tension: 100,
          friction: 8,
        })
      ]).start();
      setShowAddModal(false);
    } else {
      // Open modal - rotate to x
      Animated.parallel([
        Animated.timing(rotateAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 1.1,
          useNativeDriver: true,
          tension: 100,
          friction: 8,
        })
      ]).start();
      setShowAddModal(true);
    }
  };

  const handleAddArticle = async () => {
    try {
      const clipboardContent = await Clipboard.getStringAsync();
      
      if (!clipboardContent || !clipboardContent.trim()) {
        Alert.alert('No URL Found', 'Please copy a URL to your clipboard first, then try again.');
        return;
      }
      
      if (!clipboardContent.startsWith('http')) {
        Alert.alert('Invalid URL', 'Please copy a valid URL starting with http:// or https://');
        return;
      }

      // Reset button animation and close modal
      Animated.parallel([
        Animated.timing(rotateAnim, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.spring(scaleAnim, {
          toValue: 1,
          useNativeDriver: true,
          tension: 100,
          friction: 8,
        })
      ]).start();
      
      setShowAddModal(false);
      setIsLoading(true);
      
      try {
        const article = await extractArticleFromUrl(clipboardContent.trim());
        setSelectedArticle(article);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      } catch (extractionError) {
        const errorMessage = extractionError instanceof Error ? extractionError.message : 'Failed to extract article content';
        Alert.alert('Extraction Failed', errorMessage);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      } finally {
        setIsLoading(false);
      }
    } catch (error) {
      setIsLoading(false);
      Alert.alert('Error', 'Something went wrong. Please try again.');
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    }
  };

  const handleLongPress = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setDeleteMode(true);
    
    // Hide search when entering delete mode
    if (showSearch) {
      setShowSearch(false);
      setSearchQuery('');
    }
    
    // Clear any deleting states
    setDeletingArticles(new Set());
  };

  // Animate delete buttons when delete mode changes
  useEffect(() => {
    if (deleteMode) {
      // Small delay to ensure buttons are rendered first
      setTimeout(() => {
        Animated.spring(deleteButtonsScale, {
          toValue: 1,
          useNativeDriver: true,
          tension: 150,
          friction: 8,
        }).start();
      }, 50);
    }
  }, [deleteMode]);

  const handleDeleteArticle = async (articleId: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    
    // Find the article to animate its deletion
    const articleToDelete = articles.find(article => article.id === articleId);
    if (articleToDelete) {
      // Create a temporary scale animation for this specific article
      const deleteScale = new Animated.Value(1);
      
      // Animate the article shrinking
      Animated.spring(deleteScale, {
        toValue: 0,
        useNativeDriver: true,
        tension: 200,
        friction: 10,
      }).start(() => {
        // Remove article after animation completes
        const updatedArticles = articles.filter(article => article.id !== articleId);
        setArticles(updatedArticles);
        AsyncStorage.setItem('articles', JSON.stringify(updatedArticles));
        
        // Exit delete mode if no articles left
        if (updatedArticles.length === 0) {
          setDeleteMode(false);
          deleteButtonsScale.setValue(0);
        }
      });
      
      // Store the animation reference for this article
      articleToDelete.deleteAnimation = deleteScale;
    }
  };

  const toggleBookmark = async (articleId: string) => {
    try {
      const updatedArticles = articles.map(article => 
        article.id === articleId 
          ? { ...article, bookmarked: !article.bookmarked }
          : article
      );
      
      setArticles(updatedArticles);
      await AsyncStorage.setItem('articles', JSON.stringify(updatedArticles));
      
      // Update selected article if it's the one being bookmarked
      if (selectedArticle && selectedArticle.id === articleId) {
        setSelectedArticle({ ...selectedArticle, bookmarked: !selectedArticle.bookmarked });
      }
      
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    } catch (error) {
      console.error('Error toggling bookmark:', error);
    }
  };

  const exitDeleteMode = () => {
    // Animate delete buttons disappearing
    Animated.spring(deleteButtonsScale, {
      toValue: 0,
      useNativeDriver: true,
      tension: 150,
      friction: 8,
    }).start(() => {
      setDeleteMode(false);
    });
    
    // Also hide search when entering delete mode
    if (showSearch) {
      setShowSearch(false);
      setSearchQuery('');
    }
    
    // Clear any deleting states
    setDeletingArticles(new Set());
  };

  const renderArticleCard = (article: Article) => {
    const cardScale = new Animated.Value(1);
    const deleteScale = new Animated.Value(1);
    const isDeleting = deletingArticles.has(article.id);
    
    const handlePressIn = () => {
      if (!isDeleting) {
        Animated.spring(cardScale, {
          toValue: 0.95,
          useNativeDriver: true,
          tension: 300,
          friction: 10,
        }).start();
      }
    };
    
    const handlePressOut = () => {
      if (!isDeleting) {
        Animated.spring(cardScale, {
          toValue: 1,
          useNativeDriver: true,
          tension: 300,
          friction: 10,
        }).start();
      }
    };
    
    const handlePress = () => {
      if (!deleteMode && !isDeleting) {
        Haptics.selectionAsync();
        setSelectedArticle(article);
      }
    };
    
    const handleDelete = () => {
      setDeletingArticles(prev => new Set(prev).add(article.id));
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      
      // Animate the article shrinking
      Animated.spring(deleteScale, {
        toValue: 0,
        useNativeDriver: true,
        tension: 200,
        friction: 10,
      }).start(() => {
        // Remove article after animation completes
        const updatedArticles = articles.filter(a => a.id !== article.id);
        setArticles(updatedArticles);
        AsyncStorage.setItem('articles', JSON.stringify(updatedArticles));
        
        // Remove from deleting set
        setDeletingArticles(prev => {
          const newSet = new Set(prev);
          newSet.delete(article.id);
          return newSet;
        });
        
        // Exit delete mode if no articles left
        if (updatedArticles.length === 0) {
          setDeleteMode(false);
          deleteButtonsScale.setValue(0);
        }
      });
    };
    
    return (
      <Animated.View
        key={article.id}
        style={[
          styles.articleCard,
          {
            backgroundColor: colors.surface,
            transform: [
              { scale: Animated.multiply(cardScale, deleteScale) },
            ],
          },
        ]}
      >
        <TouchableOpacity
          style={styles.articleCardTouchable}
          onPress={handlePress}
          onPressIn={handlePressIn}
          onPressOut={handlePressOut}
          onLongPress={handleLongPress}
          delayLongPress={500}
          activeOpacity={0.9}
          disabled={isDeleting}
        >
          {article.imageUrl && (
            <Image source={{ uri: article.imageUrl }} style={styles.articleImage} />
          )}
          <View style={styles.articleInfo}>
            <Text style={[styles.articleTitle, { color: colors.text }]} numberOfLines={3}>
              {article.title}
            </Text>
            <Text style={[styles.articleDate, { color: colors.textMuted }]}>{article.date}</Text>
          </View>
        </TouchableOpacity>
        {/* Always render delete button but make it invisible when not in delete mode */}
        <Animated.View
          style={[
            styles.deleteButton,
            {
              backgroundColor: colors.surface2,
              opacity: deleteMode ? 1 : 0,
              transform: [
                { scale: deleteButtonsScale },
                {
                  rotate: deleteButtonsScale.interpolate({
                    inputRange: [0, 1],
                    outputRange: ['180deg', '0deg'],
                  }),
                },
              ],
            },
          ]}
          pointerEvents={deleteMode ? 'auto' : 'none'}
        >
          <TouchableOpacity
            style={styles.deleteButtonTouchable}
            onPress={handleDelete}
            activeOpacity={0.7}
            disabled={isDeleting}
          >
            <Ionicons name="close" size={16} color={colors.icon} />
          </TouchableOpacity>
        </Animated.View>
      </Animated.View>
    );
  };

  const renderArticleContent = (article: Article) => {
    const content = article.content;
    const inlineImages = article.inlineImages || [];
    
    // Split content by image placeholders and render mixed content
    const parts = content.split(/(\[IMAGE_\d+\][^\n]*)/g);
    const contentElements: React.ReactElement[] = [];
    
    parts.forEach((part, index) => {
      const imageMatch = part.match(/\[IMAGE_(\d+)\](.*)$/);
      
      if (imageMatch) {
        const imageIndex = parseInt(imageMatch[1]);
        const imageCaption = imageMatch[2].trim().replace(/^-\s*/, '');
        const imageUrl = inlineImages[imageIndex];
        
        if (imageUrl) {
          contentElements.push(
            <View key={`image-${index}`} style={styles.inlineImageContainer}>
              <Image 
                source={{ uri: imageUrl }} 
                style={styles.inlineImage}
                resizeMode="cover"
              />
              {imageCaption && (
                <Text style={styles.imageCaption}>{imageCaption}</Text>
              )}
            </View>
          );
        }
      } else if (part.trim()) {
        // Split text content into paragraphs and format them
        const paragraphs = part.split('\n\n').filter(p => p.trim());
        
        paragraphs.forEach((paragraph, pIndex) => {
          const trimmedParagraph = paragraph.trim();
          if (!trimmedParagraph) return;
          
          // Detect different content types and style accordingly
          if (trimmedParagraph.startsWith('## ')) {
            // Heading
            contentElements.push(
              <Text key={`heading-${index}-${pIndex}`} style={[styles.readerHeading, { color: colors.text }]} selectable selectionColor={colors.icon}>
                {trimmedParagraph.replace('## ', '')}
              </Text>
            );
          } else if (trimmedParagraph.startsWith('> ')) {
            // Quote
            contentElements.push(
              <View key={`quote-${index}-${pIndex}`} style={[styles.quoteContainer, { backgroundColor: colors.surface, borderLeftColor: colors.border }]}>
                <Text style={[styles.readerQuote, { color: colors.text }]} selectable selectionColor={colors.icon}>
                  {trimmedParagraph.replace('> ', '')}
                </Text>
              </View>
            );
          } else if (trimmedParagraph.startsWith('*') && trimmedParagraph.endsWith('*')) {
            // Caption
            contentElements.push(
              <Text key={`caption-${index}-${pIndex}`} style={[styles.readerCaption, { color: colors.textMuted }]} selectable selectionColor={colors.icon}>
                {trimmedParagraph.replace(/^\*|\*$/g, '')}
              </Text>
            );
          } else if (trimmedParagraph.startsWith('• ')) {
            // List item
            contentElements.push(
              <Text key={`list-${index}-${pIndex}`} style={[styles.readerListItem, { color: colors.text }]} selectable selectionColor={colors.icon}>
                {trimmedParagraph}
              </Text>
            );
          } else {
            // Regular paragraph
            contentElements.push(
              <Text key={`paragraph-${index}-${pIndex}`} style={[styles.readerText, { color: colors.text }]} selectable selectionColor={colors.icon}>
                {trimmedParagraph}
              </Text>
            );
          }
        });
      }
    });
    
    return contentElements;
  };

  const renderArticleReader = () => (
    <Modal visible={!!selectedArticle} animationType="slide" presentationStyle="fullScreen">
      <View style={[styles.readerContainer, { backgroundColor: colors.bg }]}>
        <View style={styles.readerHeader}>
          <TouchableOpacity 
            style={[styles.backButtonContainer, { backgroundColor: colors.chip }]}
            onPress={() => setSelectedArticle(null)}
          >
            <Ionicons name="arrow-back" size={24} color={colors.icon} />
          </TouchableOpacity>
          <View style={styles.readerHeaderRight}>
            <TouchableOpacity 
              style={[styles.readerHeaderButton, { backgroundColor: colors.chip }]}
              onPress={() => selectedArticle && toggleBookmark(selectedArticle.id)}
            >
              <Ionicons 
                name={selectedArticle?.bookmarked ? "bookmark" : "bookmark-outline"} 
                size={20} 
                color={colors.icon} 
              />
            </TouchableOpacity>
            <TouchableOpacity style={[styles.readerHeaderButton, { backgroundColor: colors.chip }]}>
              <Ionicons name="share-outline" size={20} color={colors.icon} />
            </TouchableOpacity>
          </View>
        </View>
        
        {selectedArticle && (
          <ScrollView style={styles.readerContent} showsVerticalScrollIndicator={false}>
            <Text style={[styles.readerTitle, { color: colors.text }]} selectable selectionColor={colors.icon}>{selectedArticle.title}</Text>
            <Text style={[styles.readerDate, { color: colors.textMuted }]} selectable selectionColor={colors.icon}>{selectedArticle.date}</Text>
            {selectedArticle.imageUrl && (
              <Image 
                source={{ uri: selectedArticle.imageUrl }} 
                style={styles.readerImage}
                resizeMode="cover"
              />
            )}
            <View style={styles.articleContentContainer}>
              {renderArticleContent(selectedArticle)}
            </View>
          </ScrollView>
        )}
        
        {/* Article Reader Action Buttons */}
        {selectedArticle && (
          <>
            <Animated.View style={[styles.readerLeftButton, { backgroundColor: colors.surface, transform: [{ scale: leftButtonScale }] }]}>
              <TouchableOpacity
                style={styles.readerButtonTouchable}
                onPressIn={() => {
                  Animated.spring(leftButtonScale, {
                    toValue: 0.95,
                    useNativeDriver: true,
                    tension: 300,
                    friction: 10,
                  }).start();
                }}
                onPressOut={() => {
                  Animated.spring(leftButtonScale, {
                    toValue: 1,
                    useNativeDriver: true,
                    tension: 300,
                    friction: 10,
                  }).start();
                }}
                activeOpacity={1}
              >
                <Ionicons name="pencil" size={36} color={colors.icon} />
              </TouchableOpacity>
            </Animated.View>
            <Animated.View style={[styles.readerRightButton, { backgroundColor: colors.surface, transform: [{ scale: rightButtonScale }] }]}>
              <TouchableOpacity
                style={styles.readerButtonTouchable}
                onPressIn={() => {
                  Animated.spring(rightButtonScale, {
                    toValue: 0.95,
                    useNativeDriver: true,
                    tension: 300,
                    friction: 10,
                  }).start();
                }}
                onPressOut={() => {
                  Animated.spring(rightButtonScale, {
                    toValue: 1,
                    useNativeDriver: true,
                    tension: 300,
                    friction: 10,
                  }).start();
                }}
                activeOpacity={1}
              >
                <Ionicons name="book" size={36} color={colors.icon} />
              </TouchableOpacity>
            </Animated.View>
          </>
        )}
      </View>
    </Modal>
  );


  const renderAddModal = () => {
    
    return (
      <Modal visible={showAddModal} transparent animationType="none">
        <View style={styles.modalOverlay}>
          <BlurView intensity={40} style={StyleSheet.absoluteFill} />
          <View style={styles.modalContent}>
            <TouchableOpacity
              onPress={handleAddArticle}
              activeOpacity={0.8}
              disabled={isLoading}
            >
              <LinearGradient
                colors={['#474747', '#1a1a1a']}
                style={[styles.pasteButton, isLoading && styles.pasteButtonDisabled]}
              >
                {isLoading ? (
                  <View style={styles.loadingContainer}>
                    <ActivityIndicator size="small" color="#666" style={styles.loadingSpinner} />
                    <Text style={styles.pasteButtonTextLoading}>Extracting article...</Text>
                  </View>
                ) : (
                  <Text style={styles.pasteButtonText}>Paste Article URL</Text>
                )}
              </LinearGradient>
            </TouchableOpacity>

            {/* Upload file button with identical style */}
            <TouchableOpacity
              onPress={async () => {
                try {
                  const result = await DocumentPicker.getDocumentAsync({
                    type: '*/*',
                    multiple: false,
                    copyToCacheDirectory: true,
                  });
                  // Handle both SDK shapes: result.assets or result.uri
                  if ((result as any).canceled) {
                    return;
                  }
                  const asset = (result as any).assets?.[0] || result;
                  const fileName = asset.name || 'Selected file';
                  const uri = asset.uri;
                  const mimeType = asset.mimeType || 'unknown';
                  Alert.alert('File selected', `${fileName}\nType: ${mimeType}`);
                  // TODO: Process the file content (PDF, HTML, etc.) as needed
                } catch (e) {
                  console.error('File picker error', e);
                  Alert.alert('Upload failed', 'There was a problem selecting a file.');
                }
              }}
              activeOpacity={0.8}
            >
              <LinearGradient
                colors={['#474747', '#1a1a1a']}
                style={[styles.pasteButton]}
              >
                <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'center' }}>
                  <Ionicons name="cloud-upload-outline" size={18} color="#faf9f7" style={{ marginRight: 8 }} />
                  <Text style={styles.pasteButtonText}>Upload file</Text>
                </View>
              </LinearGradient>
            </TouchableOpacity>
          </View>
          
          {/* Plus button inside modal to ensure it's on top */}
          <Animated.View style={[
            styles.addButtonInModal,
            {
              backgroundColor: '#1a1918',
              borderColor: '#faf9f7',
              transform: [
                { scale: scaleAnim },
              ],
            },
          ]}>
            <TouchableOpacity
              style={styles.addButtonTouchable}
              onPress={handleAddButtonPress}
            >
              <Animated.View style={{
                transform: [
                  {
                    rotate: rotateAnim.interpolate({
                      inputRange: [0, 1],
                      outputRange: ['0deg', '45deg'],
                    }),
                  },
                ],
              }}>
                <Ionicons 
                  name="add" 
                  size={52} 
                  color="#faf9f7" 
                />
              </Animated.View>
            </TouchableOpacity>
          </Animated.View>
        </View>
      </Modal>
    );
  };

  // Get themed colors
  const colors = getTheme(darkMode);

  return (
    <View style={[styles.container, { backgroundColor: colors.bg }]}>
      <StatusBar style={darkMode ? 'light' : 'dark'} />
      
      <View style={styles.header}>
        <Text style={[styles.headerTitle, { color: colors.text } ]}>Your articles</Text>
        <View style={styles.headerActions}>
          {!deleteMode && (
            <>
              <TouchableOpacity 
                style={[styles.searchButton, { backgroundColor: colors.chip }]} 
                onPress={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                  setShowBookmarkedOnly(!showBookmarkedOnly);
                }}
              >
                <Ionicons 
                  name={showBookmarkedOnly ? "bookmark" : "bookmark-outline"} 
                  size={20} 
                  color={colors.icon} 
                />
              </TouchableOpacity>
              <TouchableOpacity style={[styles.searchButton, { backgroundColor: colors.chip }]} onPress={toggleSearch}>
                <Ionicons name="search" size={20} color={colors.icon} />
              </TouchableOpacity>
              <TouchableOpacity 
                style={[styles.searchButton, { backgroundColor: colors.chip }]} 
                onPress={handleOpenSettings}
                accessibilityLabel="Open settings"
              >
                <Ionicons name="settings-outline" size={20} color={colors.icon} />
              </TouchableOpacity>
            </>
          )}
          {deleteMode && (
            <TouchableOpacity style={styles.doneButton} onPress={exitDeleteMode}>
              <Text style={[styles.doneButtonText, { color: colors.text } ]}>Done</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {showSearch && (
        <View style={styles.searchContainer}>
          <TextInput
            style={[
              styles.searchInput,
              { backgroundColor: darkMode ? colors.surface : colors.surface,
                borderColor: colors.border,
                color: colors.text,
              }
            ]}
            placeholder="Search articles..."
            placeholderTextColor={darkMode ? '#8c8f94' : '#999'}
            value={searchQuery}
            onChangeText={setSearchQuery}
            autoFocus
            clearButtonMode="while-editing"
            selectionColor={colors.icon}
          />
        </View>
      )}

      <ScrollView 
        style={styles.articlesContainer} 
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.icon}
            colors={[colors.icon]}
            progressBackgroundColor={colors.bg}
          />
        }
      >
        <View style={styles.articlesGrid}>
          {filteredArticles.length === 0 && searchQuery ? (
            <View style={styles.noResultsContainer}>
              <Text style={[styles.noResultsText, { color: colors.text } ]}>No articles found</Text>
              <Text style={[styles.noResultsSubtext, { color: colors.textMuted } ]}>Try adjusting your search terms</Text>
            </View>
          ) : (
            filteredArticles.map(renderArticleCard)
          )}
        </View>
      </ScrollView>

      {renderArticleReader()}
      {renderAddModal()}
      
      {/* Add button only when modal is not shown */}
      {!showAddModal && (
        <Animated.View style={[
          styles.addButton,
          {
            backgroundColor: colors.surface,
            borderColor: darkMode ? 'transparent' : 'transparent',
            transform: [
              { scale: scaleAnim },
            ],
          },
        ]}>
          <TouchableOpacity
            style={styles.addButtonTouchable}
            onPress={handleAddButtonPress}
          >
            <Animated.View style={{
              transform: [
                {
                  rotate: rotateAnim.interpolate({
                    inputRange: [0, 1],
                    outputRange: ['0deg', '45deg'],
                  }),
                },
              ],
            }}>
              <Ionicons 
                name="add" 
                size={48} 
                color={colors.icon} 
              />
            </Animated.View>
          </TouchableOpacity>
        </Animated.View>
      )}
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
    paddingBottom: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#1a1a1a',
    flex: 1,
    fontFamily: Platform.OS === 'ios' ? 'Georgia-Bold' : 'serif',
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  searchButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#edebe8',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  searchContainer: {
    paddingHorizontal: 16, // Match article grid padding
    paddingBottom: 16,
  },
  searchInput: {
    backgroundColor: '#faf9f7',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#e8e6e3',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  noResultsContainer: {
    width: '100%',
    alignItems: 'center',
    paddingVertical: 40,
  },
  noResultsText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  noResultsSubtext: {
    fontSize: 14,
    color: '#999',
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
    backgroundColor: '#faf9f7',
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  articleCardTouchable: {
    width: '100%',
    borderRadius: 12,
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
    bottom: 50,
    left: '50%',
    marginLeft: -40,
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#faf9f7',
    borderWidth: 2,
    borderColor: 'transparent',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 9999,
    zIndex: 9999,
  },
  addButtonActive: {
    borderColor: '#1a1918',
  },
  addButtonTouchable: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 40,
  },
  deleteButton: {
    position: 'absolute',
    top: 8,
    right: 8,
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#faf9f7',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 2,
    elevation: 2,
  },
  deleteButtonTouchable: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 12,
  },
  doneButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  doneButtonText: {
    fontSize: 16,
    color: '#1a1918',
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 100,
  },
  whiteOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(255, 255, 255, 0.33)',
  },
  modalContent: {
    alignItems: 'center',
  },
  pasteButton: {
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 12,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 6,
  },
  pasteButtonDisabled: {
    opacity: 0.7,
  },
  pasteButtonText: {
    color: '#faf9f7',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  pasteButtonTextLoading: {
    color: '#666',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingSpinner: {
    marginRight: 8,
  },
  readerContainer: {
    flex: 1,
    backgroundColor: '#faf9f7',
  },
  readerHeader: {
    paddingTop: 70,
    paddingHorizontal: 24,
    paddingBottom: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  backButtonContainer: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#edebe8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  readerHeaderRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  readerHeaderButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#edebe8',
    justifyContent: 'center',
    alignItems: 'center',
  },
  readerContent: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 8,
  },
  readerTitle: {
    fontSize: 24,
    lineHeight: 32,
    marginBottom: 8,
    fontWeight: 'bold',
    color: '#1a1a1a',
    flex: 1,
    fontFamily: Platform.OS === 'ios' ? 'Georgia-Bold' : 'serif',
  },
  readerDate: {
    fontSize: 14,
    color: '#666',
    marginBottom: 24,
  },
  readerImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    marginTop: 16,
    marginBottom: 24,
  },
  readerText: {
    fontSize: 18,
    lineHeight: 28,
    color: '#2c2c2c',
    marginBottom: 16,
    fontFamily: Platform.OS === 'ios' ? 'Georgia' : 'serif',
  },
  articleContentContainer: {
    paddingBottom: 60,
  },
  inlineImageContainer: {
    marginVertical: 20,
    alignItems: 'center',
  },
  inlineImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    marginBottom: 8,
  },
  imageCaption: {
    fontSize: 14,
    color: '#666',
    fontStyle: 'italic',
    textAlign: 'center',
    paddingHorizontal: 16,
    lineHeight: 20,
  },
  readerHeading: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#1a1a1a',
    marginTop: 24,
    marginBottom: 12,
    lineHeight: 28,
  },
  quoteContainer: {
    borderLeftWidth: 4,
    borderLeftColor: '#e8e6e3',
    paddingLeft: 16,
    marginVertical: 16,
    backgroundColor: '#f6f4f1',
    paddingVertical: 12,
    borderRadius: 8,
  },
  readerQuote: {
    fontSize: 18,
    fontStyle: 'italic',
    color: '#555',
    lineHeight: 26,
  },
  readerCaption: {
    fontSize: 14,
    color: '#666',
    fontStyle: 'italic',
    textAlign: 'center',
    marginVertical: 8,
    lineHeight: 20,
  },
  readerListItem: {
    fontSize: 18,
    lineHeight: 28,
    color: '#2c2c2c',
    marginBottom: 8,
    paddingLeft: 8,
  },
  addButtonInModal: {
    position: 'absolute',
    bottom: 50,
    left: '50%',
    marginLeft: -40,
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#faf9f7',
    borderWidth: 3.5,
    borderColor: '#1a1918',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    zIndex: 10,
  },
  readerLeftButton: {
    position: 'absolute',
    bottom: 50,
    left: 30,
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#faf9f7',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    zIndex: 10,
  },
  readerRightButton: {
    position: 'absolute',
    bottom: 50,
    right: 30,
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#faf9f7',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    zIndex: 10,
  },
  readerButtonTouchable: {
    width: '100%',
    height: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 40,
  },
});
