use stats
go

create table STATS_participant
( id        numeric (10,0) IDENTITY NOT NULL,
  email     char (64) NOT NULL,
  password  char (8) NULL ,
  listmode  smallint NULL ,
  nonprofit int NULL ,
  team      int NULL ,
  retire_to int NULL,
  friend_a  int NULL,
  friend_b  int NULL,
  friend_c  int NULL,
  friend_d  int NULL,
  friend_e  int NULL,
  dem_yob   int NULL,
  dem_cpus  int NULL,
  dem_heard int NULL,
  dem_gender char (1) NULL,
  dem_region int NULL,
  dem_motivation int NULL
)
go

