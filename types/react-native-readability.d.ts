declare module 'react-native-readability' {
  export interface ReadabilityResult {
    title?: string;
    content?: string;
    textContent?: string;
    excerpt?: string;
    byline?: string;
    dir?: string;
    siteName?: string;
    lang?: string;
  }

  export class Readability {
    static parse(html: string, url?: string): Promise<ReadabilityResult | null>;
  }
}
