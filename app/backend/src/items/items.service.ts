import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Item } from './item.entity';

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(Item)
    private readonly itemsRepository: Repository<Item>,
  ) {}

  findAll(): Promise<Item[]> {
    return this.itemsRepository.find({ order: { createdAt: 'DESC' } });
  }

  findOne(id: number): Promise<Item> {
    return this.itemsRepository.findOneBy({ id });
  }

  create(data: Partial<Item>): Promise<Item> {
    const item = this.itemsRepository.create(data);
    return this.itemsRepository.save(item);
  }

  async update(id: number, data: Partial<Item>): Promise<Item> {
    await this.itemsRepository.update(id, data);
    return this.findOne(id);
  }

  async remove(id: number): Promise<void> {
    await this.itemsRepository.delete(id);
  }
}
