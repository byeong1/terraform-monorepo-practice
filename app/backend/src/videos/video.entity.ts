import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity()
export class Video {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ default: 'pending' })
  status: string;

  @Column({ nullable: true })
  originalKey: string;

  @Column({ nullable: true })
  hlsKey: string;

  @Column({ type: 'bigint', nullable: true })
  fileSize: number;

  @Column({ nullable: true })
  mimeType: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
