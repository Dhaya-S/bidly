export interface MediaUploadResponse {
  objectKey: string;
  url: string;
  mediaType: 'IMAGE' | 'VIDEO';
  thumbnailKey?: string;
}
