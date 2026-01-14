-- 1. Create PGMQ Queues
select pgmq.create('q_global_events');
select pgmq.create('q_notifications');
select pgmq.create('q_vectors');
