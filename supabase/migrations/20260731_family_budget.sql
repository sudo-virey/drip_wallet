    begin;

    create extension if not exists pgcrypto;

    create table if not exists public.budget_families (
    id uuid primary key default gen_random_uuid(),
    invite_code text not null unique,
    created_by uuid not null references public.profiles(id) on delete cascade,
    created_at timestamptz not null default now()
    );

    create table if not exists public.budget_family_members (
    family_id uuid not null references public.budget_families(id) on delete cascade,
    profile_id uuid not null references public.profiles(id) on delete cascade,
    role text not null default 'member',
    joined_at timestamptz not null default now(),
    primary key (family_id, profile_id)
    );

    alter table public.monthly_budgets
    add column if not exists family_id uuid references public.budget_families(id) on delete cascade;

    create unique index if not exists monthly_budgets_profile_month_unique
    on public.monthly_budgets (profile_id, month_year)
    where family_id is null;

    create unique index if not exists monthly_budgets_family_month_unique
    on public.monthly_budgets (family_id, month_year)
    where family_id is not null;

    create unique index if not exists budget_families_invite_code_unique
    on public.budget_families (invite_code);

    alter table public.budget_families enable row level security;
    alter table public.budget_family_members enable row level security;
    alter table public.monthly_budgets enable row level security;
    alter table public.expenses enable row level security;
    alter table public.recurring_transactions enable row level security;

    create or replace function public.is_budget_family_member(target_family_id uuid)
    returns boolean
    language sql
    security definer
    set search_path = public
    stable
    as $$
    select exists (
        select 1
        from public.budget_family_members members
        where members.family_id = target_family_id
        and members.profile_id = auth.uid()
    );
    $$;

    create or replace function public.has_budget_family_access(target_family_id uuid)
    returns boolean
    language sql
    security definer
    set search_path = public
    stable
    as $$
    select public.is_budget_family_member(target_family_id);
    $$;

    create or replace function public.get_budget_family_by_invite_code(invite_code text)
    returns table (
    id uuid,
    invite_code text,
    created_by uuid,
    created_at timestamptz
    )
    language sql
    security definer
    set search_path = public
    stable
    as $$
    select
        families.id,
        families.invite_code,
        families.created_by,
        families.created_at
    from public.budget_families families
    where families.invite_code = upper(trim(invite_code));
    $$;

    create or replace function public.can_access_budget(target_budget_id uuid)
    returns boolean
    language sql
    security definer
    set search_path = public
    stable
    as $$
    select exists (
        select 1
        from public.monthly_budgets budgets
        where budgets.id = target_budget_id
        and (
            budgets.profile_id = auth.uid()
            or (
            budgets.family_id is not null
            and public.has_budget_family_access(budgets.family_id)
            )
        )
    );
    $$;

    create or replace function public.shares_budget_family_with(target_profile_id uuid)
    returns boolean
    language sql
    security definer
    set search_path = public
    stable
    as $$
    select exists (
        select 1
        from public.budget_family_members viewer_members
        join public.budget_family_members target_members
        on target_members.family_id = viewer_members.family_id
        where viewer_members.profile_id = auth.uid()
        and target_members.profile_id = target_profile_id
    );
    $$;

    drop policy if exists "Users can insert their own expenses" on public.expenses;
    drop policy if exists "Users can select their own expenses" on public.expenses;
    drop policy if exists "Users can update their own expenses" on public.expenses;
    drop policy if exists "Users can delete their own budgets" on public.monthly_budgets;
    drop policy if exists "Users can insert their own budgets" on public.monthly_budgets;
    drop policy if exists "Users can select their own budgets" on public.monthly_budgets;
    drop policy if exists "Users can update their own budgets" on public.monthly_budgets;
    drop policy if exists "Users can insert their own profile" on public.profiles;
    drop policy if exists "Users can read their own profile" on public.profiles;
    drop policy if exists "Users can update their own profile" on public.profiles;
    drop policy if exists "Enable read access for all users" on public.categories;
    drop policy if exists "Policy with table joins" on public.recurring_transactions;
    drop policy if exists "Enable delete for users based on user_id" on public.recurring_transactions;
    drop policy if exists "Enable insert for authenticated users only" on public.recurring_transactions;

    drop policy if exists categories_select on public.categories;
    create policy categories_select on public.categories
    for select
    using (true);

    drop policy if exists profiles_select on public.profiles;
    create policy profiles_select on public.profiles
    for select
    using (id = auth.uid());

    drop policy if exists profiles_insert on public.profiles;
    create policy profiles_insert on public.profiles
    for insert
    with check (id = auth.uid());

    drop policy if exists profiles_update on public.profiles;
    create policy profiles_update on public.profiles
    for update
    using (id = auth.uid())
    with check (id = auth.uid());

    drop policy if exists budget_families_select on public.budget_families;
    create policy budget_families_select on public.budget_families
    for select
    using (
        created_by = auth.uid()
        or public.has_budget_family_access(budget_families.id)
    );

    drop policy if exists budget_families_insert on public.budget_families;
    create policy budget_families_insert on public.budget_families
    for insert
    with check (created_by = auth.uid());

    drop policy if exists budget_families_update on public.budget_families;
    create policy budget_families_update on public.budget_families
    for update
    using (created_by = auth.uid())
    with check (created_by = auth.uid());

    drop policy if exists budget_family_members_select on public.budget_family_members;
    create policy budget_family_members_select on public.budget_family_members
    for select
    using (profile_id = auth.uid() or public.has_budget_family_access(family_id));

    drop policy if exists budget_family_members_insert on public.budget_family_members;
    create policy budget_family_members_insert on public.budget_family_members
    for insert
    with check (profile_id = auth.uid());

    drop policy if exists budget_family_members_update on public.budget_family_members;
    create policy budget_family_members_update on public.budget_family_members
    for update
    using (profile_id = auth.uid())
    with check (profile_id = auth.uid());

    drop policy if exists monthly_budgets_select on public.monthly_budgets;
    create policy monthly_budgets_select on public.monthly_budgets
    for select
    using (
        (family_id is null and profile_id = auth.uid())
        or (family_id is not null and public.has_budget_family_access(family_id))
    );

    drop policy if exists monthly_budgets_insert on public.monthly_budgets;
    create policy monthly_budgets_insert on public.monthly_budgets
    for insert
    with check (
        (family_id is null and profile_id = auth.uid())
        or (
        family_id is not null
        and profile_id = auth.uid()
        and public.has_budget_family_access(family_id)
        )
    );

    drop policy if exists monthly_budgets_update on public.monthly_budgets;
    create policy monthly_budgets_update on public.monthly_budgets
    for update
    using (
        (family_id is null and profile_id = auth.uid())
        or (family_id is not null and public.has_budget_family_access(family_id))
    )
    with check (
        (family_id is null and profile_id = auth.uid())
        or (
        family_id is not null
        and profile_id = auth.uid()
        and public.has_budget_family_access(family_id)
        )
    );

    drop policy if exists expenses_select on public.expenses;
    create policy expenses_select on public.expenses
    for select
    using (public.can_access_budget(budget_id));

    drop policy if exists expenses_insert on public.expenses;
    create policy expenses_insert on public.expenses
    for insert
    with check (
        profile_id = auth.uid()
        and public.can_access_budget(budget_id)
    );

    drop policy if exists expenses_update on public.expenses;
    create policy expenses_update on public.expenses
    for update
    using (public.can_access_budget(budget_id))
    with check (
        profile_id = auth.uid()
        and public.can_access_budget(budget_id)
    );

    drop policy if exists expenses_delete on public.expenses;
    create policy expenses_delete on public.expenses
    for delete
    using (public.can_access_budget(budget_id));

    drop policy if exists recurring_transactions_select on public.recurring_transactions;
    create policy recurring_transactions_select on public.recurring_transactions
    for select
    using (
        profile_id = auth.uid()
        or public.shares_budget_family_with(profile_id)
    );

    drop policy if exists recurring_transactions_insert on public.recurring_transactions;
    create policy recurring_transactions_insert on public.recurring_transactions
    for insert
    with check (
        profile_id = auth.uid()
        or public.shares_budget_family_with(profile_id)
    );

    drop policy if exists recurring_transactions_update on public.recurring_transactions;
    create policy recurring_transactions_update on public.recurring_transactions
    for update
    using (
        profile_id = auth.uid()
        or public.shares_budget_family_with(profile_id)
    )
    with check (
        profile_id = auth.uid()
        or public.shares_budget_family_with(profile_id)
    );

    drop policy if exists recurring_transactions_delete on public.recurring_transactions;
    create policy recurring_transactions_delete on public.recurring_transactions
    for delete
    using (
        profile_id = auth.uid()
        or public.shares_budget_family_with(profile_id)
    );

    commit;
