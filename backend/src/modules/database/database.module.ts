import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DatabaseService } from './database.service';
import { AdminUser } from '../../entities/admin-user.entity';

@Module({
    imports: [TypeOrmModule.forFeature([AdminUser])],
    providers: [DatabaseService],
    exports: [DatabaseService],
})
export class DatabaseModule {}