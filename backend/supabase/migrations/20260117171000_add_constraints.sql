-- Add constraints to ensure data integrity

alter table public.tickets 
add constraint tickets_price_check check (price >= 0);

alter table public.tickets 
add constraint tickets_quantity_check check (quantity >= 0);

alter table public.events 
add constraint events_max_participants_check check (max_participants > 0);
