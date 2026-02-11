import { IsString, IsIn } from 'class-validator';

export class VideoCallbackDto {
  @IsString()
  videoId: string;

  @IsString()
  @IsIn(['ready', 'error'])
  status: string;
}
