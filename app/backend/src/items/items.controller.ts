import { Controller, Get, Post, Put, Delete, Param, Body } from '@nestjs/common';
import { ItemsService } from './items.service';
import { Item } from './item.entity';

@Controller('items')
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Get()
  findAll(): Promise<Item[]> {
    return this.itemsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: number): Promise<Item> {
    return this.itemsService.findOne(id);
  }

  @Post()
  create(@Body() data: Partial<Item>): Promise<Item> {
    return this.itemsService.create(data);
  }

  @Put(':id')
  update(@Param('id') id: number, @Body() data: Partial<Item>): Promise<Item> {
    return this.itemsService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: number): Promise<void> {
    return this.itemsService.remove(id);
  }
}
