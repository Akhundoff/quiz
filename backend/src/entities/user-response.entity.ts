import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, Unique } from 'typeorm';
import { QuizSession } from './quiz-session.entity';
import { Question } from './question.entity';

@Entity('user_responses')
@Unique(['sessionId', 'questionId'])
export class UserResponse {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({ name: 'session_id' })
    sessionId: string;

    @Column({ name: 'question_id' })
    questionId: number;

    @Column('text', { name: 'answer_text' })
    answerText: string;

    @ManyToOne(() => QuizSession, session => session.responses, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'session_id' })
    session: QuizSession;

    @ManyToOne(() => Question, question => question.responses, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'question_id' })
    question: Question;

    @CreateDateColumn({ name: 'created_at' })
    createdAt: Date;
}
