/* Submitted by Brian Camp */

/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

	SELECT * FROM `Facilities` WHERE membercost > 0


/* Q2: How many facilities do not charge a fee to members? */

	SELECT count(name) FROM `Facilities` WHERE membercost = 0


/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

	SELECT `facid`, `name`, `membercost`, `monthlymaintenance` 
	FROM `Facilities` 
	WHERE membercost > 0 AND membercost < 0.2*monthlymaintenance


/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

	SELECT * FROM `Facilities` WHERE `facid` in (1,5)


/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

	SELECT name, monthlymaintenance AS maint, 
	CASE WHEN monthlymaintenance < 100 THEN 'cheap' ELSE 'expensive' END AS rating
	FROM Facilities 


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */

	/* This answer reverses the order so that the first few rows of the 
	query result will be the most recent members by joindate. */
		SELECT `memid`, `surname`, `firstname`, timestamp(`joindate`) as when_joined
		FROM `Members`
		ORDER BY when_joined DESC

	/* This query returns the last member to join. */
		SELECT `memid`, `surname`, `firstname`, timestamp(`joindate`) as when_joined
		FROM `Members`
		WHERE timestamp(`joindate`) = (SELECT max(timestamp(`joindate`)) FROM `Members`)
		ORDER BY when_joined DESC

	/* This query returns any members who joined on the last joindate. In this
	case it is 2012-09-26. So if more than one person joins on that date, they would
	listed by this query. */

		SELECT `memid`, `surname`, `firstname`, timestamp(`joindate`) as when_joined
		FROM `Members`
		WHERE date(timestamp(`joindate`)) = (SELECT max(date(timestamp(`joindate`))) FROM `Members`)
		ORDER BY when_joined DESC

	
/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

	SELECT concat(mem.surname,', ',mem.firstname) as memname, fac.name, 
		   count(distinct book.bookid)     
	FROM `Bookings` book
	JOIN `Facilities` fac
	  ON book.facid = fac.facid
	JOIN `Members` mem
	  ON book.memid = mem.memid
	WHERE fac.name LIKE 'Tennis%'
	GROUP BY memname, fac.name
	ORDER BY memname, fac.name


/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

	SELECT b.bookid, f.facid, m.memid,
		date(timestamp(b.starttime)) as bookdate, 
		f.name as facility, 
		concat(m.surname, ', ', m.firstname) as person,
		CASE WHEN b.memid > 0 THEN 'member' 
			 ELSE 'guest' END AS membership,	
		CASE WHEN b.memid > 0 THEN b.slots*f.membercost
			 ELSE b.slots*f.guestcost END AS cost
	FROM Bookings b 
	LEFT JOIN Members m
	ON b.memid = m.memid
	LEFT JOIN Facilities f
	ON b.facid = f.facid
	WHERE date(timestamp(b.starttime)) = '2012-09-14'
	  AND CASE WHEN b.memid > 0 THEN b.slots*f.membercost
			 ELSE b.slots*f.guestcost END > 30
	ORDER BY cost DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

	SELECT b.bookid, f.facid, m.memid, c.bookdate,
		f.name as facility, 
		concat(m.surname, ', ', m.firstname) as person,
		CASE WHEN b.memid > 0 THEN 'member' 
			 ELSE 'guest' END AS membership,
		c.cost
	FROM Bookings b
	LEFT JOIN Facilities f
	ON b.facid = f.facid
	LEFT JOIN Members m
	ON b.memid = m.memid
	LEFT JOIN 
		(SELECT bb.bookid as bookid,
			date(bb.starttime) as bookdate,
			CASE WHEN bb.memid > 0 THEN bb.slots*ff.membercost
				 ELSE bb.slots*ff.guestcost END AS cost
		 FROM Bookings bb LEFT JOIN Facilities ff ON bb.facid = ff.facid) c
	ON b.bookid = c.bookid
	WHERE c.bookdate = '2012-09-14' AND c.cost > 30
	ORDER BY cost DESC
     	    	

/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

	SELECT f.name,
		sum(b.slots*(b.member*f.membercost + b.guest*f.guestcost)) as revenue
	FROM (SELECT *, 
			CASE WHEN memid > 0 THEN 1 ELSE 0 END as member,
			CASE WHEN memid = 0 THEN 1 ELSE 0 END as guest
		  FROM Bookings) b
	LEFT JOIN Facilities f
	ON b.facid = f.facid
	GROUP BY f.name
	HAVING revenue < 1000


