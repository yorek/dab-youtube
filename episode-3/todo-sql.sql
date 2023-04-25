use [tempdb]
go

if (db_id('dab-youtube-ep-3') is not null) begin
    alter database [dab-youtube-ep-3] set single_user with rollback immediate;
    drop database [dab-youtube-ep-3];
end
go

create database [dab-youtube-ep-3];
go
use [dab-youtube-ep-3]
go

if (not exists(select * from sys.server_principals where [name] = 'dab_sample_user' ))
begin
    create login [dab_sample_user] with password = 'lwe0S23_qmaWE';
end
create user [dab_sample_user] from login [dab_sample_user];
go
alter role db_owner add member [dab_sample_user];
go

create table [dbo].[todos]
(
	[id] [uniqueidentifier] not null,
	[title] [nvarchar](1000) not null,
	[completed] [bit] not null,
    [custom] [nvarchar](max) null,	
    [owner_id] [varchar](128) not null,
    [created_on] datetime2(7) not null,
) 
go
alter table [dbo].[todos] add primary key nonclustered 
(
	[id] asc
)
go
alter table [dbo].[todos] add default (newid()) for [id]
go
alter table [dbo].[todos] add default ((0)) for [completed]
go
alter table [dbo].[todos] add default ('public') for [owner_id]
go
alter table [dbo].[todos] add default (sysutcdatetime()) for [created_on]
go
alter table [dbo].[todos] add check (isjson(custom) = 1)
go

delete from  [dbo].[todos] 
go
insert into [dbo].[todos] 
    (id, title, completed, owner_id) 
values 
    (newid(), 'test anonymous', 0, 'public'),
    (newid(), 'test authenticated 1', 0, '12345'),
    (newid(), 'test authenticated 2', 0, '56789'),
    (newid(), 'test authenticated 3', 0, 'john@contoso.com')
go

alter table [dbo].[todos] add [position] int null
go
update t    
set t.[position] = s.n
from [dbo].[todos] t 
inner join (
    select row_number() over(order by completed) as n, * from dbo.todos
) s on t.id = s.id
go
insert into
    dbo.todos (id, title, completed, owner_id, position)
select
    newid(),
    'test item #' + format([value], '00000'),
    0,
    'public',
    null
from
    generate_series(1, 10000, 1)
go

create or alter procedure dbo.AddNewFromJSON
@payload nvarchar(max)
as
begin
    if isjson(@payload) = 0 begin
        throw 50000, '@payload must be a valid json document', 1;
    end

    insert into 
        dbo.todos (id, title, completed, owner_id, position)
    select
        newid() as id,
        *
    from
        openjson(@payload) with (
            title nvarchar(1000),
            completed bit,
            owner_id varchar(128),
            position int
        )
end
go