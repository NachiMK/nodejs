CREATE OR REPLACE FUNCTION public.DateDiff (units VARCHAR(30), start_t TIME, end_t TIME) 
     RETURNS INT AS $$
   DECLARE
     diff_interval INTERVAL; 
     diff INT = 0;
   BEGIN
     -- Minus operator for TIME returns interval 'HH:MI:SS'  
     diff_interval = end_t - start_t;
 
     diff = DATE_PART('hour', diff_interval);
 
     IF units IN ('hh', 'hour') THEN
       RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('minute', diff_interval);
 
     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('second', diff_interval);
 
     RETURN diff;
   END;
   $$ LANGUAGE plpgsql;
   