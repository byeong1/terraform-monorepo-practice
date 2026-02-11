import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThan, Repository } from 'typeorm';
import {
  S3Client,
  PutObjectCommand,
  CreateMultipartUploadCommand,
  UploadPartCommand,
  CompleteMultipartUploadCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Video } from './video.entity';
import { CreateVideoDto } from './dto/create-video.dto';

@Injectable()
export class VideosService {
  private readonly logger = new Logger(VideosService.name);
  private s3: S3Client;
  private bucket: string;
  private cloudfrontDomain: string;

  constructor(
    @InjectRepository(Video)
    private readonly videosRepository: Repository<Video>,
  ) {
    this.s3 = new S3Client({ region: process.env.AWS_REGION || 'ap-northeast-2' });
    this.bucket = process.env.MEDIA_BUCKET_NAME || '';
    this.cloudfrontDomain = process.env.CLOUDFRONT_DOMAIN || '';
  }

  async create(dto: CreateVideoDto) {
    const video = this.videosRepository.create({
      title: dto.title,
      mimeType: dto.mimeType,
      fileSize: dto.fileSize,
      status: 'pending',
    });
    const saved = await this.videosRepository.save(video);

    const key = `uploads/${saved.id}/original.mp4`;
    saved.originalKey = key;
    await this.videosRepository.save(saved);

    const command = new PutObjectCommand({ Bucket: this.bucket, Key: key });
    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 3600 });

    return { video: saved, uploadUrl };
  }

  async initMultipartUpload(id: string) {
    const video = await this.findOne(id);
    const key = video.originalKey || `uploads/${id}/original.mp4`;

    const command = new CreateMultipartUploadCommand({
      Bucket: this.bucket,
      Key: key,
    });
    const response = await this.s3.send(command);

    if (!video.originalKey) {
      video.originalKey = key;
      await this.videosRepository.save(video);
    }

    return { uploadId: response.UploadId, key };
  }

  async getMultipartUploadUrl(id: string, uploadId: string, partNumber: number) {
    const video = await this.findOne(id);
    const command = new UploadPartCommand({
      Bucket: this.bucket,
      Key: video.originalKey,
      UploadId: uploadId,
      PartNumber: partNumber,
    });
    const url = await getSignedUrl(this.s3, command, { expiresIn: 3600 });
    return { url, partNumber };
  }

  async completeMultipartUpload(
    id: string,
    uploadId: string,
    parts: { ETag: string; PartNumber: number }[],
  ) {
    const video = await this.findOne(id);
    const command = new CompleteMultipartUploadCommand({
      Bucket: this.bucket,
      Key: video.originalKey,
      UploadId: uploadId,
      MultipartUpload: { Parts: parts },
    });
    await this.s3.send(command);

    video.status = 'encoding';
    await this.videosRepository.save(video);

    return { message: 'Upload completed' };
  }

  findAll(): Promise<Video[]> {
    return this.videosRepository.find({ order: { createdAt: 'DESC' } });
  }

  async findOne(id: string): Promise<Video> {
    const video = await this.videosRepository.findOneBy({ id });
    if (!video) throw new NotFoundException(`Video ${id} not found`);
    return video;
  }

  async findOneWithHls(id: string) {
    const video = await this.findOne(id);
    let hlsUrl: string | null = null;

    if (video.status === 'ready' && this.cloudfrontDomain) {
      hlsUrl = `https://${this.cloudfrontDomain}/${video.id}/original.m3u8`;
    }

    return { ...video, hlsUrl };
  }

  async handleCallback(videoId: string, status: string) {
    const video = await this.findOne(videoId);
    video.status = status;
    if (status === 'ready') {
      video.hlsKey = `hls/${videoId}/`;
    }
    return this.videosRepository.save(video);
  }

  async remove(id: string): Promise<void> {
    const video = await this.findOne(id);

    // S3에서 uploads/ 관련 파일 삭제
    if (video.originalKey) {
      await this.deleteS3Object(video.originalKey);
    }

    // S3에서 hls/ 관련 파일 삭제
    if (video.hlsKey) {
      await this.deleteS3Prefix(`hls/${id}/`);
    }

    await this.videosRepository.delete(id);
  }

  @Cron(CronExpression.EVERY_HOUR)
  async cleanupStalePending(): Promise<void> {
    const threshold = new Date(Date.now() - 60 * 60 * 1000);

    const staleVideos = await this.videosRepository.find({
      where: {
        status: 'pending',
        createdAt: LessThan(threshold),
      },
    });

    if (staleVideos.length === 0) return;

    this.logger.log(`Cleaning up ${staleVideos.length} stale pending video(s)`);

    for (const video of staleVideos) {
      try {
        if (video.originalKey) {
          await this.deleteS3Object(video.originalKey);
        }
        await this.videosRepository.delete(video.id);
        this.logger.log(`Cleaned up stale video: ${video.id}`);
      } catch (error) {
        this.logger.error(`Failed to cleanup video ${video.id}:`, error);
      }
    }
  }

  private async deleteS3Object(key: string) {
    try {
      await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
    } catch (e) {
      console.error(`Failed to delete S3 object ${key}:`, e);
    }
  }

  private async deleteS3Prefix(prefix: string) {
    try {
      const listResult = await this.s3.send(
        new ListObjectsV2Command({ Bucket: this.bucket, Prefix: prefix }),
      );
      const objects = listResult.Contents || [];
      for (const obj of objects) {
        await this.deleteS3Object(obj.Key);
      }
    } catch (e) {
      console.error(`Failed to delete S3 prefix ${prefix}:`, e);
    }
  }
}
