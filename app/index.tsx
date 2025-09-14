import { Ionicons } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Clipboard from 'expo-clipboard';
import * as Haptics from 'expo-haptics';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Animated, Dimensions, Image, Modal, Platform, RefreshControl, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

interface Article {
  id: string;
  title: string;
  url: string;
  content: string;
  date: string;
  imageUrl?: string;
  inlineImages?: string[];
  deleteAnimation?: any;
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
  const [articles, setArticles] = useState<Article[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [selectedArticle, setSelectedArticle] = useState<Article | null>(null);
  const [deleteMode, setDeleteMode] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [refreshing, setRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [deletingArticles, setDeletingArticles] = useState<Set<string>>(new Set());
  const rotateAnim = new Animated.Value(0);
  const scaleAnim = new Animated.Value(1);
  const deleteButtonsScale = new Animated.Value(0);

  useEffect(() => {
    loadArticles();
  }, []);

  const onRefresh = async () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    await loadArticles(true);
  };

  const filteredArticles = articles.filter(article =>
    article.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const toggleSearch = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setShowSearch(!showSearch);
    if (showSearch) {
      setSearchQuery('');
    }
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
            <Text style={styles.articleTitle} numberOfLines={3}>
              {article.title}
            </Text>
            <Text style={styles.articleDate}>{article.date}</Text>
          </View>
        </TouchableOpacity>
        {deleteMode && (
          <Animated.View
            style={[
              styles.deleteButton,
              {
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
          >
            <TouchableOpacity
              style={styles.deleteButtonTouchable}
              onPress={handleDelete}
              activeOpacity={0.7}
              disabled={isDeleting}
            >
              <Ionicons name="close" size={16} color="#000000" />
            </TouchableOpacity>
          </Animated.View>
        )}
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
              <Text key={`heading-${index}-${pIndex}`} style={styles.readerHeading}>
                {trimmedParagraph.replace('## ', '')}
              </Text>
            );
          } else if (trimmedParagraph.startsWith('> ')) {
            // Quote
            contentElements.push(
              <View key={`quote-${index}-${pIndex}`} style={styles.quoteContainer}>
                <Text style={styles.readerQuote}>
                  {trimmedParagraph.replace('> ', '')}
                </Text>
              </View>
            );
          } else if (trimmedParagraph.startsWith('*') && trimmedParagraph.endsWith('*')) {
            // Caption
            contentElements.push(
              <Text key={`caption-${index}-${pIndex}`} style={styles.readerCaption}>
                {trimmedParagraph.replace(/^\*|\*$/g, '')}
              </Text>
            );
          } else if (trimmedParagraph.startsWith('• ')) {
            // List item
            contentElements.push(
              <Text key={`list-${index}-${pIndex}`} style={styles.readerListItem}>
                {trimmedParagraph}
              </Text>
            );
          } else {
            // Regular paragraph
            contentElements.push(
              <Text key={`paragraph-${index}-${pIndex}`} style={styles.readerText}>
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
      <View style={styles.readerContainer}>
        <View style={styles.readerHeader}>
          <TouchableOpacity 
            style={styles.backButtonContainer}
            onPress={() => setSelectedArticle(null)}
          >
            <Ionicons name="close" size={20} color="#666" />
          </TouchableOpacity>
        </View>
        
        {selectedArticle && (
          <ScrollView style={styles.readerContent} showsVerticalScrollIndicator={false}>
            <Text style={styles.readerTitle}>{selectedArticle.title}</Text>
            <Text style={styles.readerDate}>{selectedArticle.date}</Text>
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
      </View>
    </Modal>
  );

  const renderAddModal = () => {
    const modalScale = new Animated.Value(showAddModal ? 1 : 0.8);
    const modalOpacity = new Animated.Value(showAddModal ? 1 : 0);
    
    React.useEffect(() => {
      if (showAddModal) {
        Animated.parallel([
          Animated.spring(modalScale, {
            toValue: 1,
            useNativeDriver: true,
            tension: 100,
            friction: 8,
          }),
          Animated.timing(modalOpacity, {
            toValue: 1,
            duration: 200,
            useNativeDriver: true,
          }),
        ]).start();
      }
    }, [showAddModal]);
    
    return (
      <Modal visible={showAddModal} transparent animationType="none">
        <Animated.View style={[styles.modalOverlay, { opacity: modalOpacity }]}>
          <Animated.View
            style={[
              styles.modalContent,
              {
                transform: [{ scale: modalScale }],
              },
            ]}
          >
            <TouchableOpacity
              onPress={handleAddArticle}
              activeOpacity={0.8}
              disabled={isLoading}
            >
                      <LinearGradient
                colors={['#ffffff', '#f5f5f5']}
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
            <TouchableOpacity
              style={styles.cancelButton}
              onPress={handleAddButtonPress}
              activeOpacity={0.6}
            >
              <Text style={styles.cancelButtonText}>Cancel</Text>
            </TouchableOpacity>
          </Animated.View>
        </Animated.View>
      </Modal>
    );
  };

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Your articles</Text>
        <View style={styles.headerActions}>
          {!deleteMode && (
            <TouchableOpacity style={styles.searchButton} onPress={toggleSearch}>
              <Ionicons name="search" size={20} color="#666" />
            </TouchableOpacity>
          )}
          {deleteMode && (
            <TouchableOpacity style={styles.doneButton} onPress={exitDeleteMode}>
              <Text style={styles.doneButtonText}>Done</Text>
            </TouchableOpacity>
          )}
        </View>
      </View>

      {showSearch && (
        <View style={styles.searchContainer}>
          <TextInput
            style={styles.searchInput}
            placeholder="Search articles..."
            placeholderTextColor="#999"
            value={searchQuery}
            onChangeText={setSearchQuery}
            autoFocus
            clearButtonMode="while-editing"
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
            tintColor="#666"
            colors={['#666']}
            progressBackgroundColor="#f8f9fa"
          />
        }
      >
        <View style={styles.articlesGrid}>
          {filteredArticles.length === 0 && searchQuery ? (
            <View style={styles.noResultsContainer}>
              <Text style={styles.noResultsText}>No articles found</Text>
              <Text style={styles.noResultsSubtext}>Try adjusting your search terms</Text>
            </View>
          ) : (
            filteredArticles.map(renderArticleCard)
          )}
        </View>
      </ScrollView>

      {renderAddModal()}
      {renderArticleReader()}
      
      <Animated.View style={[
        styles.addButton,
        showAddModal && styles.addButtonActive,
        {
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
              color="#000000" 
            />
          </Animated.View>
        </TouchableOpacity>
      </Animated.View>
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
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#1a1a1a',
    flex: 1,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  searchButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#f0f0f0',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  searchContainer: {
    paddingHorizontal: 16, // Match article grid padding
    paddingBottom: 16,
  },
  searchInput: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    fontSize: 16,
    borderWidth: 1,
    borderColor: '#e0e0e0',
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
    backgroundColor: '#ffffff',
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
    backgroundColor: '#ffffff',
    borderWidth: 2,
    borderColor: 'transparent',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
    zIndex: 10,
  },
  addButtonActive: {
    borderColor: '#000000',
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
    backgroundColor: '#ffffff',
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
    color: '#000000',
    fontWeight: '600',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(248, 249, 250, 0.95)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1,
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
    color: '#000000',
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
    paddingBottom: 16,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  backButtonContainer: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#f0f0f0',
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
    borderLeftColor: '#e0e0e0',
    paddingLeft: 16,
    marginVertical: 16,
    backgroundColor: '#f8f9fa',
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
});
