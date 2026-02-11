import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  Headers,
  ForbiddenException,
} from '@nestjs/common';
import { VideosService } from './videos.service';
import { CreateVideoDto } from './dto/create-video.dto';
import { VideoCallbackDto } from './dto/video-callback.dto';

@Controller('videos')
export class VideosController {
  constructor(private readonly videosService: VideosService) {}

  @Post()
  create(@Body() dto: CreateVideoDto) {
    return this.videosService.create(dto);
  }

  @Post(':id/multipart/init')
  initMultipart(@Param('id') id: string) {
    return this.videosService.initMultipartUpload(id);
  }

  @Post(':id/multipart/url')
  getPartUrl(
    @Param('id') id: string,
    @Body() body: { uploadId: string; partNumber: number },
  ) {
    return this.videosService.getMultipartUploadUrl(id, body.uploadId, body.partNumber);
  }

  @Post(':id/multipart/complete')
  completeMultipart(
    @Param('id') id: string,
    @Body() body: { uploadId: string; parts: { ETag: string; PartNumber: number }[] },
  ) {
    return this.videosService.completeMultipartUpload(id, body.uploadId, body.parts);
  }

  @Get()
  findAll() {
    return this.videosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.videosService.findOneWithHls(id);
  }

  @Post('callback')
  callback(
    @Body() dto: VideoCallbackDto,
    @Headers('x-callback-secret') secret: string,
  ) {
    const expected = process.env.CALLBACK_SECRET || '';
    if (!expected || secret !== expected) {
      throw new ForbiddenException('Invalid callback secret');
    }
    return this.videosService.handleCallback(dto.videoId, dto.status);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.videosService.remove(id);
  }
}
