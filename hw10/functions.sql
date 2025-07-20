Create or replace function random_string(length integer) returns text as
$$
declare
  chars text[] := '{a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
  result text := '';
  i integer := 0;
begin
  if length < 0 then
    raise exception 'Given length cannot be less than 0';
  end if;
  for i in 1..length loop
    result := result || chars[1+random()*(array_length(chars, 1)-1)];
  end loop;
  return result;
end;
$$ language plpgsql;

------------------------------------------------------------------------------
Create or replace function random_word() returns text as
$$
declare
  result text := '';
begin
  result := random_string((3 + random() * 7)::integer);
  return result;
end;
$$ language plpgsql;

------------------------------------------------------------------------------
Create or replace function random_sentence() returns text as
$$
declare
  result text := '';
begin
  for i in 1..5 loop
    result := result || random_word();
    if i < 5 then
      result := result || ' ';
    end if;
  end loop;
  return result;
end;
$$ language plpgsql;
