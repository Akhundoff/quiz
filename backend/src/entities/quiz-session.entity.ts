import { Entity, PrimaryColumn, Column, OneToMany, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { UserResponse } from './user-response.entity';

@Entity('quiz_sessions')
export class QuizSession {
    @PrimaryColumn()
    id: string; // UUID

    @Column({ name: 'user_name', nullable: true })
    userName: string;

    @Column({ name: 'is_completed', default: false })
    isCompleted: boolean;

    @Column({ name: 'completed_at', nullable: true })
    completedAt: Date;

    @OneToMany(() => UserResponse, response => response.session)
    responses: UserResponse[];

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;

    @UpdateDateColumn({ name: 'updated_at' })
    updatedAt: Date;
}