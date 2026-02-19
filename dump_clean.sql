--
-- PostgreSQL database dump
--

\restrict 9MQqlcEm0ymzS5JCnddoqZPt7dSfDl5kuifpIKDEFURnbvGCyfCp4dVKN3W0Kx0

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 18.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auction_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auction_events (
    auction_event_id integer NOT NULL,
    auction_house_id integer,
    event_name text NOT NULL,
    location text,
    event_date date,
    currency text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: auction_events_auction_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auction_events_auction_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auction_events_auction_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auction_events_auction_event_id_seq OWNED BY public.auction_events.auction_event_id;


--
-- Name: auction_houses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auction_houses (
    auction_house_id integer NOT NULL,
    name text NOT NULL,
    website text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: auction_houses_auction_house_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auction_houses_auction_house_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auction_houses_auction_house_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auction_houses_auction_house_id_seq OWNED BY public.auction_houses.auction_house_id;


--
-- Name: auction_lots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auction_lots (
    id bigint NOT NULL,
    auction_house text NOT NULL,
    auction_id text NOT NULL,
    lot integer NOT NULL,
    brand text NOT NULL,
    reference_code text,
    model text,
    price numeric NOT NULL,
    currency text DEFAULT 'CHF'::text NOT NULL,
    url text NOT NULL,
    image_url text,
    auction_date date NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: auction_lots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auction_lots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auction_lots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auction_lots_id_seq OWNED BY public.auction_lots.id;


--
-- Name: brands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brands (
    brand_id integer NOT NULL,
    brand_name text NOT NULL
);


--
-- Name: brands_brand_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.brands_brand_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: brands_brand_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.brands_brand_id_seq OWNED BY public.brands.brand_id;


--
-- Name: demand_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demand_scores (
    snapshot_date date NOT NULL,
    reference_id integer NOT NULL,
    sellability_score integer NOT NULL,
    exit_confidence text NOT NULL,
    expected_exit_min integer NOT NULL,
    expected_exit_max integer NOT NULL,
    price_risk_band text NOT NULL,
    market_depth text NOT NULL,
    CONSTRAINT demand_scores_exit_confidence_check CHECK ((exit_confidence = ANY (ARRAY['High'::text, 'Medium'::text, 'Low'::text]))),
    CONSTRAINT demand_scores_market_depth_check CHECK ((market_depth = ANY (ARRAY['Thin'::text, 'Moderate'::text, 'Deep'::text]))),
    CONSTRAINT demand_scores_price_risk_band_check CHECK ((price_risk_band = ANY (ARRAY['Low'::text, 'Medium'::text, 'High'::text]))),
    CONSTRAINT demand_scores_sellability_score_check CHECK (((sellability_score >= 0) AND (sellability_score <= 100)))
);


--
-- Name: listings_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.listings_daily (
    snapshot_date date NOT NULL,
    reference_id integer NOT NULL,
    avg_price numeric NOT NULL,
    min_price numeric NOT NULL,
    listing_count integer NOT NULL,
    avg_days_on_market integer
);


--
-- Name: market_listings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.market_listings (
    id integer NOT NULL,
    source text NOT NULL,
    brand text,
    model text,
    reference_code text,
    price numeric,
    currency text,
    url text,
    collected_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: market_listings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.market_listings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: market_listings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.market_listings_id_seq OWNED BY public.market_listings.id;


--
-- Name: models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.models (
    model_id integer NOT NULL,
    brand_id integer NOT NULL,
    model_name text NOT NULL
);


--
-- Name: models_model_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.models_model_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: models_model_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.models_model_id_seq OWNED BY public.models.model_id;


--
-- Name: watch_index_brand_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_index_brand_daily (
    id bigint NOT NULL,
    brand text NOT NULL,
    index_date date NOT NULL,
    lot_count integer NOT NULL,
    total_value numeric(18,2) NOT NULL,
    avg_price numeric(18,2) NOT NULL,
    median_price numeric(18,2),
    unique_references integer NOT NULL,
    demand_score numeric(10,4) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: watch_index_brand_daily_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_index_brand_daily_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_index_brand_daily_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_index_brand_daily_id_seq OWNED BY public.watch_index_brand_daily.id;


--
-- Name: watch_index_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_index_daily (
    id bigint NOT NULL,
    brand text NOT NULL,
    reference_code text,
    index_date date NOT NULL,
    lot_count integer NOT NULL,
    total_value numeric(18,2) NOT NULL,
    avg_price numeric(18,2) NOT NULL,
    median_price numeric(18,2),
    demand_score numeric(10,4) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: watch_index_daily_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_index_daily_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_index_daily_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_index_daily_id_seq OWNED BY public.watch_index_daily.id;


--
-- Name: watch_index_market_daily; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_index_market_daily (
    id bigint NOT NULL,
    index_date date NOT NULL,
    lot_count integer NOT NULL,
    total_value numeric(18,2) NOT NULL,
    avg_price numeric(18,2) NOT NULL,
    median_price numeric(18,2),
    unique_brands integer NOT NULL,
    unique_references integer NOT NULL,
    demand_score numeric(12,4) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: watch_index_market_daily_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_index_market_daily_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_index_market_daily_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_index_market_daily_id_seq OWNED BY public.watch_index_market_daily.id;


--
-- Name: watch_references; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.watch_references (
    reference_id integer NOT NULL,
    model_id integer NOT NULL,
    reference_code text NOT NULL
);


--
-- Name: watch_references_reference_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.watch_references_reference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: watch_references_reference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.watch_references_reference_id_seq OWNED BY public.watch_references.reference_id;


--
-- Name: auction_events auction_event_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_events ALTER COLUMN auction_event_id SET DEFAULT nextval('public.auction_events_auction_event_id_seq'::regclass);


--
-- Name: auction_houses auction_house_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_houses ALTER COLUMN auction_house_id SET DEFAULT nextval('public.auction_houses_auction_house_id_seq'::regclass);


--
-- Name: auction_lots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_lots ALTER COLUMN id SET DEFAULT nextval('public.auction_lots_id_seq'::regclass);


--
-- Name: brands brand_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands ALTER COLUMN brand_id SET DEFAULT nextval('public.brands_brand_id_seq'::regclass);


--
-- Name: market_listings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_listings ALTER COLUMN id SET DEFAULT nextval('public.market_listings_id_seq'::regclass);


--
-- Name: models model_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models ALTER COLUMN model_id SET DEFAULT nextval('public.models_model_id_seq'::regclass);


--
-- Name: watch_index_brand_daily id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_brand_daily ALTER COLUMN id SET DEFAULT nextval('public.watch_index_brand_daily_id_seq'::regclass);


--
-- Name: watch_index_daily id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_daily ALTER COLUMN id SET DEFAULT nextval('public.watch_index_daily_id_seq'::regclass);


--
-- Name: watch_index_market_daily id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_market_daily ALTER COLUMN id SET DEFAULT nextval('public.watch_index_market_daily_id_seq'::regclass);


--
-- Name: watch_references reference_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_references ALTER COLUMN reference_id SET DEFAULT nextval('public.watch_references_reference_id_seq'::regclass);


--
-- Data for Name: auction_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auction_events (auction_event_id, auction_house_id, event_name, location, event_date, currency, created_at) FROM stdin;
1	1	Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-11 12:33:33.920436
2	1	Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:14:00.05617
3	1	Phillips Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:22:42.358278
4	1	Phillips Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:26:12.117773
5	1	Phillips Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:27:54.712209
6	1	Phillips Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:30:59.391084
7	1	Phillips Geneva Watch Auction November 2025	\N	2025-11-08	CHF	2026-02-12 00:35:05.722759
\.


--
-- Data for Name: auction_houses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auction_houses (auction_house_id, name, website, created_at) FROM stdin;
1	Phillips	https://www.phillips.com	2026-02-11 11:26:28.992386
\.


--
-- Data for Name: auction_lots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auction_lots (id, auction_house, auction_id, lot, brand, reference_code, model, price, currency, url, image_url, auction_date, created_at) FROM stdin;
599	PHILLIPS	CH080425	161	Vacheron Constantin	4020T/000R-B654	Traditionnelle Complete Calendar Openface	33020.0	CHF	https://www.phillips.com/detail/vacheron-constantin/224309	\N	2025-04-08	2026-02-18 06:34:27.531361+00
600	PHILLIPS	CH080425	154	Vianney Halter	\N	Classic	50800.0	CHF	https://www.phillips.com/detail/vianney-halter/222528	\N	2025-04-08	2026-02-18 06:34:27.531361+00
601	PHILLIPS	CH080425	155	Voutilainen	\N	Observatoire	381000.0	CHF	https://www.phillips.com/detail/voutilainen/223968	\N	2025-04-08	2026-02-18 06:34:27.531361+00
602	PHILLIPS	CH080425	118	Yosuke Sekiguchi	\N	Primvère	95250.0	CHF	https://www.phillips.com/detail/yosuke-sekiguchi/224317	\N	2025-04-08	2026-02-18 06:34:27.531361+00
416	PHILLIPS	CH080425	209	A. Lange & Söhne	\N	Quarter Repeating Grande & Petite Sonnerie	254000.0	CHF	https://www.phillips.com/detail/a.-lange-&-söhne/222282	\N	2025-04-08	2026-02-18 06:34:27.531361+00
417	PHILLIPS	CH080425	11	A. Lange & Söhne	\N	"Jump Seconds"	342900.0	CHF	https://www.phillips.com/detail/a.-lange-&-söhne/222284	\N	2025-04-08	2026-02-18 06:34:27.531361+00
418	PHILLIPS	CH080425	208	A. Lange & Söhne	405.034	Datograph Up/Down "Lumen"	203200.0	CHF	https://www.phillips.com/detail/a.-lange-&-söhne/223109	\N	2025-04-08	2026-02-18 06:34:27.531361+00
419	PHILLIPS	CH080425	210	A. Lange & Söhne	425.050	1815 Rattrapante Hommage to F.A. Lange	203200.0	CHF	https://www.phillips.com/detail/a.-lange-&-söhne/223300	\N	2025-04-08	2026-02-18 06:34:27.531361+00
420	PHILLIPS	CH080425	10	A. Lange & Söhne	405.031	Datograph Up/Down	60960.0	CHF	https://www.phillips.com/detail/a.-lange-&-söhne/224809	\N	2025-04-08	2026-02-18 06:34:27.531361+00
421	PHILLIPS	CH080425	44	Agassiz	\N	Set of 2 Worldtimers	76200.0	CHF	https://www.phillips.com/detail/agassiz/222684	\N	2025-04-08	2026-02-18 06:34:27.531361+00
422	PHILLIPS	CH080425	63	Andersen Geneve	465	Minute Repeater "Unique Piece"	114300.0	CHF	https://www.phillips.com/detail/andersen-geneve/222203	\N	2025-04-08	2026-02-18 06:34:27.531361+00
423	PHILLIPS	CH080425	25	Angelus	\N	"Doctor's Watch"	13970.0	CHF	https://www.phillips.com/detail/angelus/191621	\N	2025-04-08	2026-02-18 06:34:27.531361+00
424	PHILLIPS	CH080425	46	Audemars Piguet	25559BA	Quantieme Perpetuel	44450.0	CHF	https://www.phillips.com/detail/audemars-piguet/214887	\N	2025-04-08	2026-02-18 06:34:27.531361+00
425	PHILLIPS	CH080425	108	Audemars Piguet	5403BA	"Cobra"	40640.0	CHF	https://www.phillips.com/detail/audemars-piguet/220671	\N	2025-04-08	2026-02-18 06:34:27.531361+00
426	PHILLIPS	CH080425	203	Audemars Piguet	25829ST	Royal Oak	190500.0	CHF	https://www.phillips.com/detail/audemars-piguet/221415	\N	2025-04-08	2026-02-18 06:34:27.531361+00
427	PHILLIPS	CH080425	165	Audemars Piguet	26533OR.OO.1220OR.01	Royal Oak Selfwinding Flying Tourbillon	228600.0	CHF	https://www.phillips.com/detail/audemars-piguet/221789	\N	2025-04-08	2026-02-18 06:34:27.531361+00
428	PHILLIPS	CH080425	179	Audemars Piguet	26591TI.OO.1252TI.02	Royal Oak “Minute Repeater Supersonnerie”	203200.0	CHF	https://www.phillips.com/detail/audemars-piguet/222070	\N	2025-04-08	2026-02-18 06:34:27.531361+00
429	PHILLIPS	CH080425	90	Audemars Piguet	154120R.YG.1224OR.01	Royal Oak Frosted Gold Double Balance Wheel Openworked "Rainbow"	317500.0	CHF	https://www.phillips.com/detail/audemars-piguet/222127	\N	2025-04-08	2026-02-18 06:34:27.531361+00
430	PHILLIPS	CH080425	50	Audemars Piguet	5402BA	Royal Oak "Jumbo"	63500.0	CHF	https://www.phillips.com/detail/audemars-piguet/222973	\N	2025-04-08	2026-02-18 06:34:27.531361+00
431	PHILLIPS	CH080425	45	Audemars Piguet	25829TR	Royal Oak Quantième Perpetuel	355600.0	CHF	https://www.phillips.com/detail/audemars-piguet/223299	\N	2025-04-08	2026-02-18 06:34:27.531361+00
432	PHILLIPS	CH080425	180	Audemars Piguet	15407ST	Royal Oak Double Balance	127000.0	CHF	https://www.phillips.com/detail/audemars-piguet/224028	\N	2025-04-08	2026-02-18 06:34:27.531361+00
433	PHILLIPS	CH080425	48	Audemars Piguet	16202BA.OO.1240BA.01	Royal Oak "Jumbo" Extra-Thin "	88900.0	CHF	https://www.phillips.com/detail/audemars-piguet/224308	\N	2025-04-08	2026-02-18 06:34:27.531361+00
434	PHILLIPS	CH080425	53	Audemars Piguet	26331IP	Royal Oak Chronograph “20th Anniversary”	88900.0	CHF	https://www.phillips.com/detail/audemars-piguet/224310	\N	2025-04-08	2026-02-18 06:34:27.531361+00
435	PHILLIPS	CH080425	109	Breguet	3237	A very attractive and rare yellow gold chronograph wristwatch with lapis lazuli hour and minute track	66040.0	CHF	https://www.phillips.com/detail/breguet/210755	\N	2025-04-08	2026-02-18 06:34:27.531361+00
436	PHILLIPS	CH080425	202	Breguet	3610	A very complicated, charismatic and exquisitely decorated yellow gold perpetual calendar chronograph wristwatch with moonphases, leap year indication, officier lugs and engine-turned dial	53340.0	CHF	https://www.phillips.com/detail/breguet/210757	\N	2025-04-08	2026-02-18 06:34:27.531361+00
437	PHILLIPS	CH080425	201	Breguet	3050	An exquisite and remarkable yellow gold perpetual calendar automatic wristwatch with moonphases, leap year indication, engine-turned dial and bracelet	40640.0	CHF	https://www.phillips.com/detail/breguet/210819	\N	2025-04-08	2026-02-18 06:34:27.531361+00
438	PHILLIPS	CH080425	150	Breguet	\N	Type XX "Esso"	76200.0	CHF	https://www.phillips.com/detail/breguet/218663	\N	2025-04-08	2026-02-18 06:34:27.531361+00
439	PHILLIPS	CH080425	149	Breguet	\N	"Jump Hour"	76200.0	CHF	https://www.phillips.com/detail/breguet/222460	\N	2025-04-08	2026-02-18 06:34:27.531361+00
440	PHILLIPS	CH080425	22	Breguet	\N	"Equation of Time"	241300.0	CHF	https://www.phillips.com/detail/breguet/222999	\N	2025-04-08	2026-02-18 06:34:27.531361+00
441	PHILLIPS	CH080425	148	Breguet	\N	Minute Repeating Perpetual Calendar - Unique	69850.0	CHF	https://www.phillips.com/detail/breguet/223002	\N	2025-04-08	2026-02-18 06:34:27.531361+00
442	PHILLIPS	CH080425	113	Breguet	3355	Classique Complications Tourbillon Squelette	82550.0	CHF	https://www.phillips.com/detail/breguet/223298	\N	2025-04-08	2026-02-18 06:34:27.531361+00
443	PHILLIPS	CH080425	110	Breguet	3737	A complicated and extremely rare yellow gold minute repeating perpetual calendar wristwatch with guilloche dial, moon phases, leap year indication, certificate of origin and presentation box	152400.0	CHF	https://www.phillips.com/detail/breguet/223705	\N	2025-04-08	2026-02-18 06:34:27.531361+00
444	PHILLIPS	CH080425	133	Cartier and Audemars Piguet	\N	An intriguing and elegant yellow gold special order skeletonized wristwatch, with movement by Audemars Piguet	114300.0	CHF	https://www.phillips.com/detail/cartier-and-audemars-piguet/221688	\N	2025-04-08	2026-02-18 06:34:27.531361+00
445	PHILLIPS	CH080425	130	Cartier Paris Londres	\N	A rare belle epoque nephrite, gold and diamond-set pendulette clock with 8 day movement and presentation box	57150.0	CHF	https://www.phillips.com/detail/cartier-paris-londres/222286	\N	2025-04-08	2026-02-18 06:34:27.531361+00
446	PHILLIPS	CH080425	134	Cartier Paris	\N	Model A	698500.0	CHF	https://www.phillips.com/detail/cartier-paris/222293	\N	2025-04-08	2026-02-18 06:34:27.531361+00
447	PHILLIPS	CH080425	131	Cartier Paris	\N	A rare and attractive onyx square desk clock with 8 day movement, lapis lazuli dial, diamond-set indexes and turquoise decoration	76200.0	CHF	https://www.phillips.com/detail/cartier-paris/222295	\N	2025-04-08	2026-02-18 06:34:27.531361+00
448	PHILLIPS	CH080425	132	Cartier	\N	Rectangulaire	114300.0	CHF	https://www.phillips.com/detail/cartier/221607	\N	2025-04-08	2026-02-18 06:34:27.531361+00
449	PHILLIPS	CH080425	62	Cartier	ined tortue-shaped platinum wristwatch number 40 of a 200 pieces limited edition	Tortue Collection Privée	24130.0	CHF	https://www.phillips.com/detail/cartier/221776	\N	2025-04-08	2026-02-18 06:34:27.531361+00
450	PHILLIPS	CH080425	112	Cartier	2846	Tank Chronographe Monopoussoir	40640.0	CHF	https://www.phillips.com/detail/cartier/221937	\N	2025-04-08	2026-02-18 06:34:27.531361+00
451	PHILLIPS	CH080425	146	Cartier	2488	Tank Asymétrique	62230.0	CHF	https://www.phillips.com/detail/cartier/223904	\N	2025-04-08	2026-02-18 06:34:27.531361+00
452	PHILLIPS	CH080425	173	Cartier	4466 and WHSA0044	Santos Dumont Skeleton Micro-rotor	30480.0	CHF	https://www.phillips.com/detail/cartier/224311	\N	2025-04-08	2026-02-18 06:34:27.531361+00
453	PHILLIPS	CH080425	158	Cecil Purnell	CP.01WG Spherion	Spherion Tourbillon	60960.0	CHF	https://www.phillips.com/detail/cecil-purnell/221619	\N	2025-04-08	2026-02-18 06:34:27.531361+00
454	PHILLIPS	CH080425	55	Cédric Johner	\N	Abysse Chronograph 30th Anniversary "Prototype"	63500.0	CHF	https://www.phillips.com/detail/cédric-johner/222473	\N	2025-04-08	2026-02-18 06:34:27.531361+00
455	PHILLIPS	CH080425	135	Charles Frodsham	\N	Split-Seconds Minute Repeating Tourbillon	406400.0	CHF	https://www.phillips.com/detail/charles-frodsham/222281	\N	2025-04-08	2026-02-18 06:34:27.531361+00
456	PHILLIPS	CH080425	152	Credor	GBBL993	A very rare and attractive platinum skeletonized chronograph wristwatch with mother-of-pearl registers, power reserve indication, original guarantee and presentation box	63500.0	CHF	https://www.phillips.com/detail/credor/224381	\N	2025-04-08	2026-02-18 06:34:27.531361+00
457	PHILLIPS	CH080425	42	Credor	GBBD963	Engraved Skeleton Limited Edition	76200.0	CHF	https://www.phillips.com/detail/credor/225426	\N	2025-04-08	2026-02-18 06:34:27.531361+00
458	PHILLIPS	CH080425	4	Daniel Roth	C187	Tourbillon Double Face	127000.0	CHF	https://www.phillips.com/detail/daniel-roth/220389	\N	2025-04-08	2026-02-18 06:34:27.531361+00
459	PHILLIPS	CH080425	96	Daniel Roth	C317	Papillon	110490.0	CHF	https://www.phillips.com/detail/daniel-roth/224700	\N	2025-04-08	2026-02-18 06:34:27.531361+00
460	PHILLIPS	CH080425	183	David Candaux	DC12 "Emblème"	DC12 Embème "Prototype"	203200.0	CHF	https://www.phillips.com/detail/david-candaux/224682	\N	2025-04-08	2026-02-18 06:34:27.531361+00
461	PHILLIPS	CH080425	156	De Bethune	DB1	DB1	152400.0	CHF	https://www.phillips.com/detail/de-bethune/221938	\N	2025-04-08	2026-02-18 06:34:27.531361+00
462	PHILLIPS	CH080425	119	De Bethune	DB28GSV2AN	DB28GS Grand Bleu	88900.0	CHF	https://www.phillips.com/detail/de-bethune/223026	\N	2025-04-08	2026-02-18 06:34:27.531361+00
463	PHILLIPS	CH080425	175	De Bethune	CS240	Dream Watch 5	139700.0	CHF	https://www.phillips.com/detail/de-bethune/224101	\N	2025-04-08	2026-02-18 06:34:27.531361+00
464	PHILLIPS	CH080425	177	Derek Pratt for Urban Jürgensen	\N	Minute repeating perpetual calendar	139700.0	CHF	https://www.phillips.com/detail/derek-pratt-for-urban-jürgensen/222218	\N	2025-04-08	2026-02-18 06:34:27.531361+00
465	PHILLIPS	CH080425	211	Dürstein and Cie	\N	Grand Complication	355600.0	CHF	https://www.phillips.com/detail/dürstein-and-cie/222301	\N	2025-04-08	2026-02-18 06:34:27.531361+00
466	PHILLIPS	CH080425	24	Eterna	\N	"Pulsation Dial"	9525.0	CHF	https://www.phillips.com/detail/eterna/191657	\N	2025-04-08	2026-02-18 06:34:27.531361+00
467	PHILLIPS	CH080425	97	F.P. Journe	\N	Tourbillon Souverain "Régence Circulaire"	1693500.0	CHF	https://www.phillips.com/detail/f.p.-journe/220638	\N	2025-04-08	2026-02-18 06:34:27.531361+00
468	PHILLIPS	CH080425	115	F.P. Journe	\N	Octa Quantieme Perpetual Calendar "Boutique Edition"	228600.0	CHF	https://www.phillips.com/detail/f.p.-journe/221373	\N	2025-04-08	2026-02-18 06:34:27.531361+00
469	PHILLIPS	CH080425	159	F.P. Journe	ined platinum wristwatch with vertical tourbillon regulator, Certificate, invoice and box; "Black Label" edition	Tourbillon Souverain - Black Label	762000.0	CHF	https://www.phillips.com/detail/f.p.-journe/221374	\N	2025-04-08	2026-02-18 06:34:27.531361+00
470	PHILLIPS	CH080425	182	F.P. Journe	\N	Chronomètre à Résonance "Souscription"	3327000.0	CHF	https://www.phillips.com/detail/f.p.-journe/221651	\N	2025-04-08	2026-02-18 06:34:27.531361+00
471	PHILLIPS	CH080425	61	F.P. Journe	\N	Tourbillon Souverain "Ruthenium"	596900.0	CHF	https://www.phillips.com/detail/f.p.-journe/222214	\N	2025-04-08	2026-02-18 06:34:27.531361+00
472	PHILLIPS	CH080425	58	F.P. Journe	\N	Chronographe Monopoussoir Rattrapante	266700.0	CHF	https://www.phillips.com/detail/f.p.-journe/222232	\N	2025-04-08	2026-02-18 06:34:27.531361+00
473	PHILLIPS	CH080425	5	F.P. Journe	\N	Octa Perpétuelle "Tokyo Edition"	431800.0	CHF	https://www.phillips.com/detail/f.p.-journe/223608	\N	2025-04-08	2026-02-18 06:34:27.531361+00
474	PHILLIPS	CH080425	6	Ferdinand Berthoud	\N	Naissance d'Une Montre 3 "Pièce Unique"	1270000.0	CHF	https://www.phillips.com/detail/ferdinand-berthoud/224836	\N	2025-04-08	2026-02-18 06:34:27.531361+00
475	PHILLIPS	CH080425	60	Franck Muller	2870 NADF	Chronographe Double Face	19050.0	CHF	https://www.phillips.com/detail/franck-muller/223055	\N	2025-04-08	2026-02-18 06:34:27.531361+00
476	PHILLIPS	CH080425	181	Genus	GNS1.2TD Dragon	A whimsical and inventive damascene titanium wristwatch with combined "dragon"/hand minute indication, rotating and revolving hour numerals, Certificate and box	50800.0	CHF	https://www.phillips.com/detail/genus/220519	\N	2025-04-08	2026-02-18 06:34:27.531361+00
477	PHILLIPS	CH080425	153	Grand Seiko	4580-7000	45GS VFA	33020.0	CHF	https://www.phillips.com/detail/grand-seiko/224380	\N	2025-04-08	2026-02-18 06:34:27.531361+00
478	PHILLIPS	CH080425	128	Grand Seiko	4520-8010	070'459	12700.0	CHF	https://www.phillips.com/detail/grand-seiko/225428	\N	2025-04-08	2026-02-18 06:34:27.531361+00
479	PHILLIPS	CH080425	176	Grönefeld	\N	Parallax Tourbillon "Unique Piece"	114300.0	CHF	https://www.phillips.com/detail/grönefeld/220549	\N	2025-04-08	2026-02-18 06:34:27.531361+00
480	PHILLIPS	CH080425	98	H. Moser & Cie X MB&F	1810-1205	H. Moser x MB&F Endeavour Cylindrical Tourbillon	60960.0	CHF	https://www.phillips.com/detail/h.-moser-&-cie-x-mb&f/221833	\N	2025-04-08	2026-02-18 06:34:27.531361+00
481	PHILLIPS	CH080425	124	H. Moser & Cie	\N	"The Time Capsule"	39370.0	CHF	https://www.phillips.com/detail/h.-moser-&-cie/223687	\N	2025-04-08	2026-02-18 06:34:27.531361+00
482	PHILLIPS	CH080425	72	Hajime Asaoka	\N	Tsunami “Art Deco” Prototype	228600.0	CHF	https://www.phillips.com/detail/hajime-asaoka/220548	\N	2025-04-08	2026-02-18 06:34:27.531361+00
483	PHILLIPS	CH080425	174	Heuer	2447S	Carrera	8890.0	CHF	https://www.phillips.com/detail/heuer/191665	\N	2025-04-08	2026-02-18 06:34:27.531361+00
484	PHILLIPS	CH080425	125	Heuer	2447T	Carrera 12	12700.0	CHF	https://www.phillips.com/detail/heuer/191667	\N	2025-04-08	2026-02-18 06:34:27.531361+00
485	PHILLIPS	CH080425	172	Heuer	3336 N	Pre Carrera	7620.0	CHF	https://www.phillips.com/detail/heuer/215852	\N	2025-04-08	2026-02-18 06:34:27.531361+00
486	PHILLIPS	CH080425	151	IWC	325	Portugieser	55880.0	CHF	https://www.phillips.com/detail/iwc/222454	\N	2025-04-08	2026-02-18 06:34:27.531361+00
487	PHILLIPS	CH080425	171	IWC	3750	Da Vinci Perpetual Calendar	15240.0	CHF	https://www.phillips.com/detail/iwc/222513	\N	2025-04-08	2026-02-18 06:34:27.531361+00
488	PHILLIPS	CH080425	39	J. Player & Sons	\N	"Hyper Complication"	2238000.0	CHF	https://www.phillips.com/detail/j.-player-&-sons/222299	\N	2025-04-08	2026-02-18 06:34:27.531361+00
489	PHILLIPS	CH080425	91	Jaeger-LeCoultre	Q5273480	Master Grande Tradition Tourbillon Céleste	57150.0	CHF	https://www.phillips.com/detail/jaeger-lecoultre/221787	\N	2025-04-08	2026-02-18 06:34:27.531361+00
490	PHILLIPS	CH080425	160	Jaeger-LeCoultre	270.6.49	Reverso Platinum Number One	33020.0	CHF	https://www.phillips.com/detail/jaeger-lecoultre/222221	\N	2025-04-08	2026-02-18 06:34:27.531361+00
491	PHILLIPS	CH080425	41	Kikuchi Nakagawa	\N	Murakumo	64770.0	CHF	https://www.phillips.com/detail/kikuchi-nakagawa/214959	\N	2025-04-08	2026-02-18 06:34:27.531361+00
492	PHILLIPS	CH080425	157	Konstantin Chaykin	\N	Joker "Fiat Lux Prototype"	44450.0	CHF	https://www.phillips.com/detail/konstantin-chaykin/223348	\N	2025-04-08	2026-02-18 06:34:27.531361+00
493	PHILLIPS	CH080425	57	Laurent Ferrier	\N	Galet Micro-Rotor 40mm "Pièce Unique"	97790.0	CHF	https://www.phillips.com/detail/laurent-ferrier/221564	\N	2025-04-08	2026-02-18 06:34:27.531361+00
494	PHILLIPS	CH080425	178	Lederer	CIC 9012.60.801	Central Impulse Chronometer	101600.0	CHF	https://www.phillips.com/detail/lederer/222629	\N	2025-04-08	2026-02-18 06:34:27.531361+00
495	PHILLIPS	CH080425	126	Longines	6630	Swissair	44450.0	CHF	https://www.phillips.com/detail/longines/224504	\N	2025-04-08	2026-02-18 06:34:27.531361+00
496	PHILLIPS	CH080425	7	Louis Berthoud	\N	N°52 - Marine Chronometer	406400.0	CHF	https://www.phillips.com/detail/louis-berthoud/222296	\N	2025-04-08	2026-02-18 06:34:27.531361+00
497	PHILLIPS	CH080425	3	MB&F	04.TR.GBP	Legacy Machine Split Escapement EVO	78740.0	CHF	https://www.phillips.com/detail/mb&f/220641	\N	2025-04-08	2026-02-18 06:34:27.531361+00
498	PHILLIPS	CH080425	73	Ondrej Berkus	\N	"Remontoire Dead Beat Seconds"	69850.0	CHF	https://www.phillips.com/detail/ondrej-berkus/221930	\N	2025-04-08	2026-02-18 06:34:27.531361+00
499	PHILLIPS	CH080425	1	Otsuka Lotec	5	A very intriguing and rare stainless steel wristwatch with satellite hours display, warranty and presentation box	21590.0	CHF	https://www.phillips.com/detail/otsuka-lotec/225124	\N	2025-04-08	2026-02-18 06:34:27.531361+00
500	PHILLIPS	CH080425	18	Patek Philippe	3424/1	"Gilbert Albert"	812800.0	CHF	https://www.phillips.com/detail/patek-philippe/191553	\N	2025-04-08	2026-02-18 06:34:27.531361+00
501	PHILLIPS	CH080425	19	Patek Philippe	\N	"Deck Chronometer"	34290.0	CHF	https://www.phillips.com/detail/patek-philippe/191590	\N	2025-04-08	2026-02-18 06:34:27.531361+00
502	PHILLIPS	CH080425	102	Patek Philippe	605	A charming and scarce yellow gold worldtime pocket watch with presentation box	57150.0	CHF	https://www.phillips.com/detail/patek-philippe/191620	\N	2025-04-08	2026-02-18 06:34:27.531361+00
503	PHILLIPS	CH080425	14	Patek Philippe	3971	An extremely sought-after, early and scarce yellow gold perpetual calendar wristwatch with moonphases, 24-hour indication, leap year indication, glazed back, large hallmarks to the side of the lugs and Certificate and box	317500.0	CHF	https://www.phillips.com/detail/patek-philippe/191663	\N	2025-04-08	2026-02-18 06:34:27.531361+00
504	PHILLIPS	CH080425	163	Patek Philippe	3700/1	Nautilus "Jumbo"	139700.0	CHF	https://www.phillips.com/detail/patek-philippe/215982	\N	2025-04-08	2026-02-18 06:34:27.531361+00
505	PHILLIPS	CH080425	188	Patek Philippe	5270J	A flawlessly preserved, highly complicated and very collectible yellow gold perpetual calendar chronograph wristwatch with moonphases, leap year indication, day/night indication, certificate, additional back and box	114300.0	CHF	https://www.phillips.com/detail/patek-philippe/219015	\N	2025-04-08	2026-02-18 06:34:27.531361+00
506	PHILLIPS	CH080425	111	Patek Philippe	3712/1A	Nautilus	114300.0	CHF	https://www.phillips.com/detail/patek-philippe/220522	\N	2025-04-08	2026-02-18 06:34:27.531361+00
507	PHILLIPS	CH080425	194	Patek Philippe	3700/1	Nautilus "Jumbo"	152400.0	CHF	https://www.phillips.com/detail/patek-philippe/220546	\N	2025-04-08	2026-02-18 06:34:27.531361+00
508	PHILLIPS	CH080425	74	Patek Philippe	3970ER	A superb, important and extremely in-demand pink gold perpetual calendar chronograph wristwatch with 24-hour indication, leap year indication, moonphases, Certificate, additional caseback and box	165100.0	CHF	https://www.phillips.com/detail/patek-philippe/221480	\N	2025-04-08	2026-02-18 06:34:27.531361+00
509	PHILLIPS	CH080425	144	Patek Philippe	1518	"Pink on Pink"	3569000.0	CHF	https://www.phillips.com/detail/patek-philippe/221650	\N	2025-04-08	2026-02-18 06:34:27.531361+00
510	PHILLIPS	CH080425	21	Patek Philippe	592	A jaw droppingly beautiful and important pink gold wristwatch with three tone pink dial and Breguet numerals, the only known in this configuration	444500.0	CHF	https://www.phillips.com/detail/patek-philippe/221725	\N	2025-04-08	2026-02-18 06:34:27.531361+00
511	PHILLIPS	CH080425	142	Patek Philippe	2524-1	"Gübelin"	647700.0	CHF	https://www.phillips.com/detail/patek-philippe/222308	\N	2025-04-08	2026-02-18 06:34:27.531361+00
512	PHILLIPS	CH080425	30	Patek Philippe	3970E	A highly rare and exceptionally well-preserved platinum perpetual calendar chronograph wristwatch with moonphases, 24-hour, leap year indication large hallmarks to the side of the lugs and certificate of origin	381000.0	CHF	https://www.phillips.com/detail/patek-philippe/222309	\N	2025-04-08	2026-02-18 06:34:27.531361+00
513	PHILLIPS	CH080425	143	Patek Philippe	ined and the only example known of a pink gold world time wristwatch with flat bezel and tear drop lugs	World Time	444500.0	CHF	https://www.phillips.com/detail/patek-philippe/222310	\N	2025-04-08	2026-02-18 06:34:27.531361+00
514	PHILLIPS	CH080425	205	Patek Philippe	570	Calatravone “Three-Tone Breguet Numerals”	196850.0	CHF	https://www.phillips.com/detail/patek-philippe/222459	\N	2025-04-08	2026-02-18 06:34:27.531361+00
515	PHILLIPS	CH080425	200	Patek Philippe	5970G-001	A new and highly coveted white gold perpetual calendar chronograph wristwatch with moon phases, 24-hour indicator, leap year indicator, certificate of origin, additional caseback and presentation box, single sealed	209550.0	CHF	https://www.phillips.com/detail/patek-philippe/222524	\N	2025-04-08	2026-02-18 06:34:27.531361+00
516	PHILLIPS	CH080425	69	Patek Philippe	5004G-015	A new and highly desirable white gold perpetual calendar split-seconds chronograph wristwatch with moon phases, leap year, 24- hour indicator, black dial, certificate of origin, solid caseback, double sealed	431800.0	CHF	https://www.phillips.com/detail/patek-philippe/222525	\N	2025-04-08	2026-02-18 06:34:27.531361+00
517	PHILLIPS	CH080425	87	Patek Philippe	5970P-001	A highly rare and attractive platinum perpetual chronograph wristwatch with moon phases, 24-hour indication, leap year indication, certificate of origin, additional case back, setting pin and presentation box, single sealed	254000.0	CHF	https://www.phillips.com/detail/patek-philippe/222526	\N	2025-04-08	2026-02-18 06:34:27.531361+00
518	PHILLIPS	CH080425	139	Patek Philippe	5004P-033	A highly important, rare and elegant platinum perpetual calendar split-seconds chronograph wristwatch with diamond indexes, moon phases, leap year, AM/PM indication, additional solid caseback, setting pin, certificate of origin, double sealed	406400.0	CHF	https://www.phillips.com/detail/patek-philippe/222527	\N	2025-04-08	2026-02-18 06:34:27.531361+00
519	PHILLIPS	CH080425	23	Patek Philippe	1518	A genre defining, historically important highly collectable stainless steel perpetual calendar chronograph wristwatch with moonphase display, one of four known	14190000.0	CHF	https://www.phillips.com/detail/patek-philippe/222585	\N	2025-04-08	2026-02-18 06:34:27.531361+00
520	PHILLIPS	CH080425	29	Patek Philippe	565	"Serpico Y Laino"	73660.0	CHF	https://www.phillips.com/detail/patek-philippe/222685	\N	2025-04-08	2026-02-18 06:34:27.531361+00
521	PHILLIPS	CH080425	207	Patek Philippe	3450	"Padellone"	190500.0	CHF	https://www.phillips.com/detail/patek-philippe/222972	\N	2025-04-08	2026-02-18 06:34:27.531361+00
522	PHILLIPS	CH080425	89	Patek Philippe	5207P	A spectacular and highly complex platinum perpetual calendar minute repeating tourbillon wristwatch with small seconds, moon phases, leap year, day and night indication, additional solid caseback, setting pin, certificate of origin and presentation box	596900.0	CHF	https://www.phillips.com/detail/patek-philippe/222975	\N	2025-04-08	2026-02-18 06:34:27.531361+00
523	PHILLIPS	CH080425	88	Patek Philippe	3424	"Gilbert Albert"	241300.0	CHF	https://www.phillips.com/detail/patek-philippe/222990	\N	2025-04-08	2026-02-18 06:34:27.531361+00
524	PHILLIPS	CH080425	38	Patek Philippe	\N	Minute Repeating, Perpetual Calendar, Chronograph	127000.0	CHF	https://www.phillips.com/detail/patek-philippe/223000	\N	2025-04-08	2026-02-18 06:34:27.531361+00
525	PHILLIPS	CH080425	20	Patek Philippe	\N	Minute Repeater	91440.0	CHF	https://www.phillips.com/detail/patek-philippe/223001	\N	2025-04-08	2026-02-18 06:34:27.531361+00
526	PHILLIPS	CH080425	68	Patek Philippe	5575G-001	A fine and attractive limited edition white gold world-time wristwatch with moon phases, certificate of origin and presentation box, made for the 175th anniversary of Patek Philippe	82550.0	CHF	https://www.phillips.com/detail/patek-philippe/223411	\N	2025-04-08	2026-02-18 06:34:27.531361+00
527	PHILLIPS	CH080425	40	Patek Philippe	1518	A very fine, important and iconic yellow gold perpetual calendar chronograph wristwatch with moonphases	635000.0	CHF	https://www.phillips.com/detail/patek-philippe/223418	\N	2025-04-08	2026-02-18 06:34:27.531361+00
528	PHILLIPS	CH080425	213	Patek Philippe	2499	"First Series"	1633000.0	CHF	https://www.phillips.com/detail/patek-philippe/223973	\N	2025-04-08	2026-02-18 06:34:27.531361+00
529	PHILLIPS	CH080425	193	Patek Philippe	5372P	A highly impressive, attractive and rare platinum perpetual calendar single-button split seconds chronograph wristwatch with moon phases, leap year, day and night indication, additional solid caseback, certificate of origin and presentation box	381000.0	CHF	https://www.phillips.com/detail/patek-philippe/224238	\N	2025-04-08	2026-02-18 06:34:27.531361+00
530	PHILLIPS	CH080425	80	Patek Philippe	2438/1	"Luminous Dial"	889000.0	CHF	https://www.phillips.com/detail/patek-philippe/224296	\N	2025-04-08	2026-02-18 06:34:27.531361+00
531	PHILLIPS	CH080425	75	Patek Philippe	658	Grande Complication	190500.0	CHF	https://www.phillips.com/detail/patek-philippe/224297	\N	2025-04-08	2026-02-18 06:34:27.531361+00
532	PHILLIPS	CH080425	164	Patek Philippe	5370P-001	A very attractive and rare platinum split seconds chronograph wristwatch with black enamel dial, Breguet numerals, additional caseback, certificate of origin and presentation box	381000.0	CHF	https://www.phillips.com/detail/patek-philippe/224360	\N	2025-04-08	2026-02-18 06:34:27.531361+00
533	PHILLIPS	CH080425	49	Patek Philippe	5976/1G-001	Nautilus 40th Anniversary	279400.0	CHF	https://www.phillips.com/detail/patek-philippe/224361	\N	2025-04-08	2026-02-18 06:34:27.531361+00
534	PHILLIPS	CH080425	162	Patek Philippe	5050J-027	"Special Order"	139700.0	CHF	https://www.phillips.com/detail/patek-philippe/224366	\N	2025-04-08	2026-02-18 06:34:27.531361+00
535	PHILLIPS	CH080425	79	Patek Philippe	5399G-010	"Shanghai Boutique Limited Edition"	107950.0	CHF	https://www.phillips.com/detail/patek-philippe/224368	\N	2025-04-08	2026-02-18 06:34:27.531361+00
536	PHILLIPS	CH080425	212	Patek Philippe	1526	An incredibly attractive incredibly rare yellow gold perpetual calendar wristwatch with moonphases and black dial, only one known	381000.0	CHF	https://www.phillips.com/detail/patek-philippe/224369	\N	2025-04-08	2026-02-18 06:34:27.531361+00
537	PHILLIPS	CH080425	114	Patek Philippe	3724/4	A dazzling and extremely rare white gold and diamond-set wristwatch with bracelet and sapphire hour markers	90170.0	CHF	https://www.phillips.com/detail/patek-philippe/224424	\N	2025-04-08	2026-02-18 06:34:27.531361+00
538	PHILLIPS	CH080425	189	Patek Philippe	534	A very well preserved and rare yellow gold wristwatch with champagne dial and Breguet numerals, the only one known in this configuration	43180.0	CHF	https://www.phillips.com/detail/patek-philippe/224503	\N	2025-04-08	2026-02-18 06:34:27.531361+00
539	PHILLIPS	CH080425	199	Patek Philippe	ined and enormously collectible pink gold "First Series" perpetual calendar wristwatch with center seconds moonphases, Frecnh import marks and French calendar, possibly the only example known with magnifying glass	"Secondi al Centro"	965200.0	CHF	https://www.phillips.com/detail/patek-philippe/224509	\N	2025-04-08	2026-02-18 06:34:27.531361+00
540	PHILLIPS	CH080425	137	Patek Philippe	5180/1G-001	A rare and "new old stock" white gold skeletonized wristwatch with bracelet and original certificate	76200.0	CHF	https://www.phillips.com/detail/patek-philippe/224520	\N	2025-04-08	2026-02-18 06:34:27.531361+00
541	PHILLIPS	CH080425	197	Patek Philippe	5520P-001	Alarm Travel Time	152400.0	CHF	https://www.phillips.com/detail/patek-philippe/224810	\N	2025-04-08	2026-02-18 06:34:27.531361+00
542	PHILLIPS	CH080425	92	Richard Daners for Gübelin	18D	"Minute Repeater Unique Piece"	101600.0	CHF	https://www.phillips.com/detail/richard-daners-for-gübelin/221610	\N	2025-04-08	2026-02-18 06:34:27.531361+00
543	PHILLIPS	CH080425	56	Richard Daners for Gübelin	\N	Bras en l'Air "Ballerina"	53340.0	CHF	https://www.phillips.com/detail/richard-daners-for-gübelin/222283	\N	2025-04-08	2026-02-18 06:34:27.531361+00
544	PHILLIPS	CH080425	26	Rolex	16520	Cosmograph Daytona	27940.0	CHF	https://www.phillips.com/detail/rolex/191645	\N	2025-04-08	2026-02-18 06:34:27.531361+00
545	PHILLIPS	CH080425	54	Rolex	16520	Cosmograph Daytona	60960.0	CHF	https://www.phillips.com/detail/rolex/194848	\N	2025-04-08	2026-02-18 06:34:27.531361+00
546	PHILLIPS	CH080425	34	Rolex	6239	Cosmograph Daytona "The Golden Pagoda"	1079500.0	CHF	https://www.phillips.com/detail/rolex/214103	\N	2025-04-08	2026-02-18 06:34:27.531361+00
547	PHILLIPS	CH080425	191	Rolex	6511	Day-Date "Gamal Abdel Nasser"	80010.0	CHF	https://www.phillips.com/detail/rolex/214532	\N	2025-04-08	2026-02-18 06:34:27.531361+00
548	PHILLIPS	CH080425	67	Rolex	116509	Cosmograph Daytona	40640.0	CHF	https://www.phillips.com/detail/rolex/215808	\N	2025-04-08	2026-02-18 06:34:27.531361+00
549	PHILLIPS	CH080425	52	Rolex	16528	Cosmograph Daytona, "4-Liner", "4 Scritte"	60960.0	CHF	https://www.phillips.com/detail/rolex/218492	\N	2025-04-08	2026-02-18 06:34:27.531361+00
550	PHILLIPS	CH080425	190	Rolex	16520, caseback stamped "16500" to the inside	Cosmograph Daytona "Arabic Numerals"	35560.0	CHF	https://www.phillips.com/detail/rolex/218496	\N	2025-04-08	2026-02-18 06:34:27.531361+00
551	PHILLIPS	CH080425	170	Rolex	6241	Cosmograph Daytona "Paul Newman - Champagne"	673100.0	CHF	https://www.phillips.com/detail/rolex/218498	\N	2025-04-08	2026-02-18 06:34:27.531361+00
552	PHILLIPS	CH080425	204	Rolex	16520	Cosmograph Daytona "Floating Porcelain Dial"	127000.0	CHF	https://www.phillips.com/detail/rolex/218627	\N	2025-04-08	2026-02-18 06:34:27.531361+00
553	PHILLIPS	CH080425	140	Rolex	8171	Padellone	254000.0	CHF	https://www.phillips.com/detail/rolex/219446	\N	2025-04-08	2026-02-18 06:34:27.531361+00
554	PHILLIPS	CH080425	186	Rolex	18238	Day-Date	48260.0	CHF	https://www.phillips.com/detail/rolex/221375	\N	2025-04-08	2026-02-18 06:34:27.531361+00
555	PHILLIPS	CH080425	83	Rolex	18238, caseback stamped 18200	Day-Date	40640.0	CHF	https://www.phillips.com/detail/rolex/221376	\N	2025-04-08	2026-02-18 06:34:27.531361+00
556	PHILLIPS	CH080425	206	Rolex	6234	Pre-Daytona	27940.0	CHF	https://www.phillips.com/detail/rolex/221603	\N	2025-04-08	2026-02-18 06:34:27.531361+00
557	PHILLIPS	CH080425	28	Rolex	6284	Oyster Perpetual	40640.0	CHF	https://www.phillips.com/detail/rolex/221604	\N	2025-04-08	2026-02-18 06:34:27.531361+00
558	PHILLIPS	CH080425	70	Rolex	6263	Cosmograph Daytona "Paul Newman" "Oyster Sotto" "RCO"	1391000.0	CHF	https://www.phillips.com/detail/rolex/221654	\N	2025-04-08	2026-02-18 06:34:27.531361+00
559	PHILLIPS	CH080425	168	Rolex	118238	Day-Date "Coral"	165100.0	CHF	https://www.phillips.com/detail/rolex/221705	\N	2025-04-08	2026-02-18 06:34:27.531361+00
560	PHILLIPS	CH080425	31	Rolex	6241	Cosmograph Daytona	228600.0	CHF	https://www.phillips.com/detail/rolex/221708	\N	2025-04-08	2026-02-18 06:34:27.531361+00
561	PHILLIPS	CH080425	120	Rolex	226679TBR	Yacht-Master	82550.0	CHF	https://www.phillips.com/detail/rolex/221782	\N	2025-04-08	2026-02-18 06:34:27.531361+00
562	PHILLIPS	CH080425	85	Rolex	228396TBR	Day-date	139700.0	CHF	https://www.phillips.com/detail/rolex/221785	\N	2025-04-08	2026-02-18 06:34:27.531361+00
563	PHILLIPS	CH080425	36	Rolex	6263	Oyster Cosmograph "Big Eyes"	88900.0	CHF	https://www.phillips.com/detail/rolex/222002	\N	2025-04-08	2026-02-18 06:34:27.531361+00
564	PHILLIPS	CH080425	195	Rolex	5513	Submariner "Explorer Dial"	158750.0	CHF	https://www.phillips.com/detail/rolex/222082	\N	2025-04-08	2026-02-18 06:34:27.531361+00
565	PHILLIPS	CH080425	185	Rolex	6542	GMT-Master "Serpico y Laino"	127000.0	CHF	https://www.phillips.com/detail/rolex/222134	\N	2025-04-08	2026-02-18 06:34:27.531361+00
566	PHILLIPS	CH080425	82	Rolex	5508	Submariner "Small Crown"	73660.0	CHF	https://www.phillips.com/detail/rolex/222135	\N	2025-04-08	2026-02-18 06:34:27.531361+00
567	PHILLIPS	CH080425	27	Rolex	971	Prince Brancard	10795.0	CHF	https://www.phillips.com/detail/rolex/222472	\N	2025-04-08	2026-02-18 06:34:27.531361+00
568	PHILLIPS	CH080425	169	Rolex	6265	Cosmograph Daytona "Big Red"	114300.0	CHF	https://www.phillips.com/detail/rolex/222807	\N	2025-04-08	2026-02-18 06:34:27.531361+00
569	PHILLIPS	CH080425	81	Rolex	6263	Cosmograph Daytona "Big Red"	107950.0	CHF	https://www.phillips.com/detail/rolex/222809	\N	2025-04-08	2026-02-18 06:34:27.531361+00
570	PHILLIPS	CH080425	86	Rolex	6241	Oyster Cosmograph "Paul Newman"	254000.0	CHF	https://www.phillips.com/detail/rolex/222897	\N	2025-04-08	2026-02-18 06:34:27.531361+00
571	PHILLIPS	CH080425	123	Rolex	6269 inside caseback stamped 6263	Cosmograph Daytona	1378900.0	CHF	https://www.phillips.com/detail/rolex/222960	\N	2025-04-08	2026-02-18 06:34:27.531361+00
572	PHILLIPS	CH080425	77	Rolex	6238	"Pre-Daytona - Galvanic Dial"	190500.0	CHF	https://www.phillips.com/detail/rolex/223639	\N	2025-04-08	2026-02-18 06:34:27.531361+00
573	PHILLIPS	CH080425	121	Rolex	6238	"Pre-Daytona"	177800.0	CHF	https://www.phillips.com/detail/rolex/223640	\N	2025-04-08	2026-02-18 06:34:27.531361+00
574	PHILLIPS	CH080425	35	Rolex	6238	"Pre-Daytona Pulsations Dial"	120650.0	CHF	https://www.phillips.com/detail/rolex/223641	\N	2025-04-08	2026-02-18 06:34:27.531361+00
575	PHILLIPS	CH080425	167	Rolex	6239, caseback stamped "6242" to the inside	Cosmograph Daytona "Paul Newman Musketeer"	273050.0	CHF	https://www.phillips.com/detail/rolex/223642	\N	2025-04-08	2026-02-18 06:34:27.531361+00
576	PHILLIPS	CH080425	84	Rolex	6263	Cosmograph Daytona	184150.0	CHF	https://www.phillips.com/detail/rolex/223643	\N	2025-04-08	2026-02-18 06:34:27.531361+00
577	PHILLIPS	CH080425	51	Rolex	116595RBOW	Cosmograph Daytona Rainbow	317500.0	CHF	https://www.phillips.com/detail/rolex/223964	\N	2025-04-08	2026-02-18 06:34:27.531361+00
578	PHILLIPS	CH080425	187	Rolex	ined and highly attractive white gold wristwatch with bracelet, center seconds, day, date, diamond-set bezel and dial sector ring, with warranty and presentation box	Day-Date	25400.0	CHF	https://www.phillips.com/detail/rolex/224200	\N	2025-04-08	2026-02-18 06:34:27.531361+00
579	PHILLIPS	CH080425	166	Rolex	16238	Datejust "Lapis Lazuli"	27940.0	CHF	https://www.phillips.com/detail/rolex/224307	\N	2025-04-08	2026-02-18 06:34:27.531361+00
580	PHILLIPS	CH080425	33	Rolex	16520 (inside caseback stamped 16500)	Cosmograph "Prototype Dial"	203200.0	CHF	https://www.phillips.com/detail/rolex/224373	\N	2025-04-08	2026-02-18 06:34:27.531361+00
581	PHILLIPS	CH080425	32	Rolex	18059	Day-Date "Rainbow Khanjar"	1079500.0	CHF	https://www.phillips.com/detail/rolex/224502	\N	2025-04-08	2026-02-18 06:34:27.531361+00
582	PHILLIPS	CH080425	184	Rolex	16600	Sea-Dweller "Polipetto"	177800.0	CHF	https://www.phillips.com/detail/rolex/224808	\N	2025-04-08	2026-02-18 06:34:27.531361+00
583	PHILLIPS	CH080425	196	Rolex	116759SANR	GMT-Master II	101600.0	CHF	https://www.phillips.com/detail/rolex/225125	\N	2025-04-08	2026-02-18 06:34:27.531361+00
584	PHILLIPS	CH080425	107	Rolex	14270	Explorer I "Follow the Rainbow"	10160.0	CHF	https://www.phillips.com/detail/rolex/225237	\N	2025-04-08	2026-02-18 06:34:27.531361+00
585	PHILLIPS	CH080425	136	S. Smith & Son	\N	"Grand Complication with Tourbillon"	88900.0	CHF	https://www.phillips.com/detail/s.-smith-&-son/222300	\N	2025-04-08	2026-02-18 06:34:27.531361+00
586	PHILLIPS	CH080425	127	Seiko	4520-8020	Astronomical Observatory Chronometer	101600.0	CHF	https://www.phillips.com/detail/seiko/225427	\N	2025-04-08	2026-02-18 06:34:27.531361+00
587	PHILLIPS	CH080425	129	Seiko	6139-6010	An early and historically significant stainless steel chronograph wristwatch	15240.0	CHF	https://www.phillips.com/detail/seiko/225429	\N	2025-04-08	2026-02-18 06:34:27.531361+00
588	PHILLIPS	CH080425	2	Simon Brette	\N	Chronomètre Artisans Edition Titane	279400.0	CHF	https://www.phillips.com/detail/simon-brette/220518	\N	2025-04-08	2026-02-18 06:34:27.531361+00
589	PHILLIPS	CH080425	71	Urban Jürgensen	ined pink gold wristwatch with guilloché dial, date, certificate of authenticity and presentation box	Big 8	63500.0	CHF	https://www.phillips.com/detail/urban-jürgensen/222197	\N	2025-04-08	2026-02-18 06:34:27.531361+00
590	PHILLIPS	CH080425	93	Urban Jürgensen	\N	Set of 2 Presentation Boxes	6985.0	CHF	https://www.phillips.com/detail/urban-jürgensen/222217	\N	2025-04-08	2026-02-18 06:34:27.531361+00
591	PHILLIPS	CH080425	59	Urban Jürgensen	\N	Minute Repeating, Perpetual Calendar, Tourbillon Unique Piece	635000.0	CHF	https://www.phillips.com/detail/urban-jürgensen/222219	\N	2025-04-08	2026-02-18 06:34:27.531361+00
592	PHILLIPS	CH080425	9	Urban Jürgensen	\N	Set of 3 Escapements	60960.0	CHF	https://www.phillips.com/detail/urban-jürgensen/222220	\N	2025-04-08	2026-02-18 06:34:27.531361+00
593	PHILLIPS	CH080425	116	Urwerk	UR-103	UR-103	40640.0	CHF	https://www.phillips.com/detail/urwerk/221935	\N	2025-04-08	2026-02-18 06:34:27.531361+00
594	PHILLIPS	CH080425	76	Vacheron Constantin	4300V	Overseas Perpetual Calendar "Ultra Slim"	69850.0	CHF	https://www.phillips.com/detail/vacheron-constantin/221777	\N	2025-04-08	2026-02-18 06:34:27.531361+00
595	PHILLIPS	CH080425	43	Vacheron Constantin	43050	Mercator "Portugal"	114300.0	CHF	https://www.phillips.com/detail/vacheron-constantin/222222	\N	2025-04-08	2026-02-18 06:34:27.531361+00
596	PHILLIPS	CH080425	47	Vacheron Constantin	6440Q	"Cioccolatone"	24130.0	CHF	https://www.phillips.com/detail/vacheron-constantin/222683	\N	2025-04-08	2026-02-18 06:34:27.531361+00
597	PHILLIPS	CH080425	66	Vacheron Constantin	43041	Saltarello "Prototype"	120650.0	CHF	https://www.phillips.com/detail/vacheron-constantin/223244	\N	2025-04-08	2026-02-18 06:34:27.531361+00
598	PHILLIPS	CH080425	65	Vacheron Constantin	6111	Chronomètre Royal	20320.0	CHF	https://www.phillips.com/detail/vacheron-constantin/223633	\N	2025-04-08	2026-02-18 06:34:27.531361+00
\.


--
-- Data for Name: brands; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.brands (brand_id, brand_name) FROM stdin;
1	Rolex
2	Patek Philippe
3	Audemars Piguet
4	A. Lange & Söhne
\.


--
-- Data for Name: demand_scores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.demand_scores (snapshot_date, reference_id, sellability_score, exit_confidence, expected_exit_min, expected_exit_max, price_risk_band, market_depth) FROM stdin;
\.


--
-- Data for Name: listings_daily; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.listings_daily (snapshot_date, reference_id, avg_price, min_price, listing_count, avg_days_on_market) FROM stdin;
\.


--
-- Data for Name: market_listings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.market_listings (id, source, brand, model, reference_code, price, currency, url, collected_at) FROM stdin;
\.


--
-- Data for Name: models; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.models (model_id, brand_id, model_name) FROM stdin;
1	1	GMT-Master II
2	1	Daytona
3	2	Perpetual Calendar
4	2	Nautilus
5	3	Royal Oak
6	4	Datograph
7	4	Lange 1
\.


--
-- Data for Name: watch_index_brand_daily; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.watch_index_brand_daily (id, brand, index_date, lot_count, total_value, avg_price, median_price, unique_references, demand_score, created_at) FROM stdin;
1	Agassiz	2025-04-08	1	76200.00	76200.00	76200.00	0	1.9646	2026-02-18 10:02:05.033154+00
2	A. Lange & Söhne	2025-04-08	5	1064260.00	212852.00	203200.00	3	4.9081	2026-02-18 10:02:05.033154+00
3	Andersen Geneve	2025-04-08	1	114300.00	114300.00	114300.00	1	2.2174	2026-02-18 10:02:05.033154+00
4	Angelus	2025-04-08	1	13970.00	13970.00	13970.00	0	1.7436	2026-02-18 10:02:05.033154+00
5	Audemars Piguet	2025-04-08	11	1748790.00	158980.91	127000.00	11	9.5728	2026-02-18 10:02:05.033154+00
6	Breguet	2025-04-08	9	858520.00	95391.11	76200.00	5	7.2801	2026-02-18 10:02:05.033154+00
7	Cartier	2025-04-08	5	271780.00	54356.00	40640.00	4	4.9303	2026-02-18 10:02:05.033154+00
8	Cartier and Audemars Piguet	2025-04-08	1	114300.00	114300.00	114300.00	0	2.0174	2026-02-18 10:02:05.033154+00
9	Cartier Paris	2025-04-08	2	774700.00	387350.00	387350.00	0	2.7667	2026-02-18 10:02:05.033154+00
10	Cartier Paris Londres	2025-04-08	1	57150.00	57150.00	57150.00	0	1.9271	2026-02-18 10:02:05.033154+00
11	Cecil Purnell	2025-04-08	1	60960.00	60960.00	60960.00	1	2.1355	2026-02-18 10:02:05.033154+00
12	Cédric Johner	2025-04-08	1	63500.00	63500.00	63500.00	0	1.9408	2026-02-18 10:02:05.033154+00
13	Charles Frodsham	2025-04-08	1	406400.00	406400.00	406400.00	0	2.1827	2026-02-18 10:02:05.033154+00
14	Credor	2025-04-08	2	139700.00	69850.00	69850.00	2	2.9436	2026-02-18 10:02:05.033154+00
15	Daniel Roth	2025-04-08	2	237490.00	118745.00	118745.00	2	3.0127	2026-02-18 10:02:05.033154+00
16	David Candaux	2025-04-08	1	203200.00	203200.00	203200.00	1	2.2924	2026-02-18 10:02:05.033154+00
17	De Bethune	2025-04-08	3	381000.00	127000.00	139700.00	3	3.7743	2026-02-18 10:02:05.033154+00
18	Derek Pratt for Urban Jürgensen	2025-04-08	1	139700.00	139700.00	139700.00	0	2.0436	2026-02-18 10:02:05.033154+00
19	Dürstein and Cie	2025-04-08	1	355600.00	355600.00	355600.00	0	2.1653	2026-02-18 10:02:05.033154+00
20	Eterna	2025-04-08	1	9525.00	9525.00	9525.00	0	1.6937	2026-02-18 10:02:05.033154+00
21	Ferdinand Berthoud	2025-04-08	1	1270000.00	1270000.00	1270000.00	0	2.3311	2026-02-18 10:02:05.033154+00
22	F.P. Journe	2025-04-08	7	7306500.00	1043785.71	596900.00	1	5.7591	2026-02-18 10:02:05.033154+00
23	Franck Muller	2025-04-08	1	19050.00	19050.00	19050.00	1	1.9840	2026-02-18 10:02:05.033154+00
24	Genus	2025-04-08	1	50800.00	50800.00	50800.00	1	2.1118	2026-02-18 10:02:05.033154+00
25	Grand Seiko	2025-04-08	2	45720.00	22860.00	22860.00	2	2.7980	2026-02-18 10:02:05.033154+00
26	Grönefeld	2025-04-08	1	114300.00	114300.00	114300.00	0	2.0174	2026-02-18 10:02:05.033154+00
27	Hajime Asaoka	2025-04-08	1	228600.00	228600.00	228600.00	0	2.1077	2026-02-18 10:02:05.033154+00
28	Heuer	2025-04-08	3	29210.00	9736.67	8890.00	3	3.4397	2026-02-18 10:02:05.033154+00
29	H. Moser & Cie	2025-04-08	1	39370.00	39370.00	39370.00	0	1.8786	2026-02-18 10:02:05.033154+00
30	H. Moser & Cie X MB&F	2025-04-08	1	60960.00	60960.00	60960.00	1	2.1355	2026-02-18 10:02:05.033154+00
31	IWC	2025-04-08	2	71120.00	35560.00	35560.00	2	2.8556	2026-02-18 10:02:05.033154+00
32	Jaeger-LeCoultre	2025-04-08	2	90170.00	45085.00	45085.00	2	2.8865	2026-02-18 10:02:05.033154+00
33	J. Player & Sons	2025-04-08	1	2238000.00	2238000.00	2238000.00	0	2.4050	2026-02-18 10:02:05.033154+00
34	Kikuchi Nakagawa	2025-04-08	1	64770.00	64770.00	64770.00	0	1.9434	2026-02-18 10:02:05.033154+00
35	Konstantin Chaykin	2025-04-08	1	44450.00	44450.00	44450.00	0	1.8944	2026-02-18 10:02:05.033154+00
36	Laurent Ferrier	2025-04-08	1	97790.00	97790.00	97790.00	0	1.9971	2026-02-18 10:02:05.033154+00
37	Lederer	2025-04-08	1	101600.00	101600.00	101600.00	1	2.2021	2026-02-18 10:02:05.033154+00
38	Longines	2025-04-08	1	44450.00	44450.00	44450.00	1	2.0944	2026-02-18 10:02:05.033154+00
39	Louis Berthoud	2025-04-08	1	406400.00	406400.00	406400.00	0	2.1827	2026-02-18 10:02:05.033154+00
40	MB&F	2025-04-08	1	78740.00	78740.00	78740.00	1	2.1689	2026-02-18 10:02:05.033154+00
41	Ondrej Berkus	2025-04-08	1	69850.00	69850.00	69850.00	0	1.9533	2026-02-18 10:02:05.033154+00
42	Otsuka Lotec	2025-04-08	1	21590.00	21590.00	21590.00	1	2.0003	2026-02-18 10:02:05.033154+00
43	Patek Philippe	2025-04-08	42	30830890.00	734068.81	225425.00	36	30.4467	2026-02-18 10:02:05.033154+00
44	Richard Daners for Gübelin	2025-04-08	2	154940.00	77470.00	77470.00	1	2.7570	2026-02-18 10:02:05.033154+00
45	Rolex	2025-04-08	41	9807605.00	239209.88	120650.00	32	28.9975	2026-02-18 10:02:05.033154+00
46	Seiko	2025-04-08	2	116840.00	58420.00	58420.00	2	2.9203	2026-02-18 10:02:05.033154+00
47	Simon Brette	2025-04-08	1	279400.00	279400.00	279400.00	0	2.1339	2026-02-18 10:02:05.033154+00
48	S. Smith & Son	2025-04-08	1	88900.00	88900.00	88900.00	0	1.9847	2026-02-18 10:02:05.033154+00
49	Urban Jürgensen	2025-04-08	4	766445.00	191611.25	62230.00	1	3.9653	2026-02-18 10:02:05.033154+00
50	Urwerk	2025-04-08	1	40640.00	40640.00	40640.00	1	2.0827	2026-02-18 10:02:05.033154+00
51	Vacheron Constantin	2025-04-08	6	382270.00	63711.67	51435.00	6	5.8747	2026-02-18 10:02:05.033154+00
52	Vianney Halter	2025-04-08	1	50800.00	50800.00	50800.00	0	1.9118	2026-02-18 10:02:05.033154+00
53	Voutilainen	2025-04-08	1	381000.00	381000.00	381000.00	0	2.1743	2026-02-18 10:02:05.033154+00
54	Yosuke Sekiguchi	2025-04-08	1	95250.00	95250.00	95250.00	0	1.9937	2026-02-18 10:02:05.033154+00
\.


--
-- Data for Name: watch_index_daily; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.watch_index_daily (id, brand, reference_code, index_date, lot_count, total_value, avg_price, median_price, demand_score, created_at) FROM stdin;
1	Agassiz	\N	2025-04-08	1	76200.00	76200.00	76200.00	2.5528	2026-02-18 09:56:31.103716+00
2	A. Lange & Söhne	405.031	2025-04-08	1	60960.00	60960.00	60960.00	2.5140	2026-02-18 09:56:31.103716+00
3	A. Lange & Söhne	405.034	2025-04-08	1	203200.00	203200.00	203200.00	2.7232	2026-02-18 09:56:31.103716+00
4	A. Lange & Söhne	425.050	2025-04-08	1	203200.00	203200.00	203200.00	2.7232	2026-02-18 09:56:31.103716+00
5	A. Lange & Söhne	\N	2025-04-08	2	596900.00	298450.00	298450.00	3.5104	2026-02-18 09:56:31.103716+00
6	Andersen Geneve	465	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
7	Angelus	\N	2025-04-08	1	13970.00	13970.00	13970.00	2.2581	2026-02-18 09:56:31.103716+00
8	Audemars Piguet	15407ST	2025-04-08	1	127000.00	127000.00	127000.00	2.6415	2026-02-18 09:56:31.103716+00
9	Audemars Piguet	154120R.YG.1224OR.01	2025-04-08	1	317500.00	317500.00	317500.00	2.8007	2026-02-18 09:56:31.103716+00
10	Audemars Piguet	16202BA.OO.1240BA.01	2025-04-08	1	88900.00	88900.00	88900.00	2.5796	2026-02-18 09:56:31.103716+00
11	Audemars Piguet	25559BA	2025-04-08	1	44450.00	44450.00	44450.00	2.4592	2026-02-18 09:56:31.103716+00
12	Audemars Piguet	25829ST	2025-04-08	1	190500.00	190500.00	190500.00	2.7120	2026-02-18 09:56:31.103716+00
13	Audemars Piguet	25829TR	2025-04-08	1	355600.00	355600.00	355600.00	2.8204	2026-02-18 09:56:31.103716+00
14	Audemars Piguet	26331IP	2025-04-08	1	88900.00	88900.00	88900.00	2.5796	2026-02-18 09:56:31.103716+00
15	Audemars Piguet	26533OR.OO.1220OR.01	2025-04-08	1	228600.00	228600.00	228600.00	2.7436	2026-02-18 09:56:31.103716+00
16	Audemars Piguet	26591TI.OO.1252TI.02	2025-04-08	1	203200.00	203200.00	203200.00	2.7232	2026-02-18 09:56:31.103716+00
17	Audemars Piguet	5402BA	2025-04-08	1	63500.00	63500.00	63500.00	2.5211	2026-02-18 09:56:31.103716+00
18	Audemars Piguet	5403BA	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
19	Breguet	3050	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
20	Breguet	3237	2025-04-08	1	66040.00	66040.00	66040.00	2.5279	2026-02-18 09:56:31.103716+00
21	Breguet	3355	2025-04-08	1	82550.00	82550.00	82550.00	2.5667	2026-02-18 09:56:31.103716+00
22	Breguet	3610	2025-04-08	1	53340.00	53340.00	53340.00	2.4908	2026-02-18 09:56:31.103716+00
23	Breguet	3737	2025-04-08	1	152400.00	152400.00	152400.00	2.6732	2026-02-18 09:56:31.103716+00
24	Breguet	\N	2025-04-08	4	463550.00	115887.50	76200.00	4.6664	2026-02-18 09:56:31.103716+00
25	Cartier	2488	2025-04-08	1	62230.00	62230.00	62230.00	2.5176	2026-02-18 09:56:31.103716+00
26	Cartier	2846	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
27	Cartier	4466 and WHSA0044	2025-04-08	1	30480.00	30480.00	30480.00	2.3936	2026-02-18 09:56:31.103716+00
28	Cartier	ined tortue-shaped platinum wristwatch number 40 of a 200 pieces limited edition	2025-04-08	1	24130.00	24130.00	24130.00	2.3530	2026-02-18 09:56:31.103716+00
29	Cartier	\N	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
30	Cartier and Audemars Piguet	\N	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
31	Cartier Paris	\N	2025-04-08	2	774700.00	387350.00	387350.00	3.5557	2026-02-18 09:56:31.103716+00
32	Cartier Paris Londres	\N	2025-04-08	1	57150.00	57150.00	57150.00	2.5028	2026-02-18 09:56:31.103716+00
33	Cecil Purnell	CP.01WG Spherion	2025-04-08	1	60960.00	60960.00	60960.00	2.5140	2026-02-18 09:56:31.103716+00
34	Cédric Johner	\N	2025-04-08	1	63500.00	63500.00	63500.00	2.5211	2026-02-18 09:56:31.103716+00
35	Charles Frodsham	\N	2025-04-08	1	406400.00	406400.00	406400.00	2.8436	2026-02-18 09:56:31.103716+00
36	Credor	GBBD963	2025-04-08	1	76200.00	76200.00	76200.00	2.5528	2026-02-18 09:56:31.103716+00
37	Credor	GBBL993	2025-04-08	1	63500.00	63500.00	63500.00	2.5211	2026-02-18 09:56:31.103716+00
38	Daniel Roth	C187	2025-04-08	1	127000.00	127000.00	127000.00	2.6415	2026-02-18 09:56:31.103716+00
39	Daniel Roth	C317	2025-04-08	1	110490.00	110490.00	110490.00	2.6173	2026-02-18 09:56:31.103716+00
40	David Candaux	DC12 "Emblème"	2025-04-08	1	203200.00	203200.00	203200.00	2.7232	2026-02-18 09:56:31.103716+00
41	De Bethune	CS240	2025-04-08	1	139700.00	139700.00	139700.00	2.6581	2026-02-18 09:56:31.103716+00
42	De Bethune	DB1	2025-04-08	1	152400.00	152400.00	152400.00	2.6732	2026-02-18 09:56:31.103716+00
43	De Bethune	DB28GSV2AN	2025-04-08	1	88900.00	88900.00	88900.00	2.5796	2026-02-18 09:56:31.103716+00
44	Derek Pratt for Urban Jürgensen	\N	2025-04-08	1	139700.00	139700.00	139700.00	2.6581	2026-02-18 09:56:31.103716+00
45	Dürstein and Cie	\N	2025-04-08	1	355600.00	355600.00	355600.00	2.8204	2026-02-18 09:56:31.103716+00
46	Eterna	\N	2025-04-08	1	9525.00	9525.00	9525.00	2.1916	2026-02-18 09:56:31.103716+00
47	Ferdinand Berthoud	\N	2025-04-08	1	1270000.00	1270000.00	1270000.00	3.0415	2026-02-18 09:56:31.103716+00
48	F.P. Journe	ined platinum wristwatch with vertical tourbillon regulator, Certificate, invoice and box; "Black Label" edition	2025-04-08	1	762000.00	762000.00	762000.00	2.9528	2026-02-18 09:56:31.103716+00
49	F.P. Journe	\N	2025-04-08	6	6544500.00	1090750.00	514350.00	6.3264	2026-02-18 09:56:31.103716+00
50	Franck Muller	2870 NADF	2025-04-08	1	19050.00	19050.00	19050.00	2.3120	2026-02-18 09:56:31.103716+00
51	Genus	GNS1.2TD Dragon	2025-04-08	1	50800.00	50800.00	50800.00	2.4823	2026-02-18 09:56:31.103716+00
52	Grand Seiko	4520-8010	2025-04-08	1	12700.00	12700.00	12700.00	2.2415	2026-02-18 09:56:31.103716+00
53	Grand Seiko	4580-7000	2025-04-08	1	33020.00	33020.00	33020.00	2.4075	2026-02-18 09:56:31.103716+00
54	Grönefeld	\N	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
55	Hajime Asaoka	\N	2025-04-08	1	228600.00	228600.00	228600.00	2.7436	2026-02-18 09:56:31.103716+00
56	Heuer	2447S	2025-04-08	1	8890.00	8890.00	8890.00	2.1796	2026-02-18 09:56:31.103716+00
57	Heuer	2447T	2025-04-08	1	12700.00	12700.00	12700.00	2.2415	2026-02-18 09:56:31.103716+00
58	Heuer	3336 N	2025-04-08	1	7620.00	7620.00	7620.00	2.1528	2026-02-18 09:56:31.103716+00
59	H. Moser & Cie	\N	2025-04-08	1	39370.00	39370.00	39370.00	2.4381	2026-02-18 09:56:31.103716+00
60	H. Moser & Cie X MB&F	1810-1205	2025-04-08	1	60960.00	60960.00	60960.00	2.5140	2026-02-18 09:56:31.103716+00
61	IWC	325	2025-04-08	1	55880.00	55880.00	55880.00	2.4989	2026-02-18 09:56:31.103716+00
62	IWC	3750	2025-04-08	1	15240.00	15240.00	15240.00	2.2732	2026-02-18 09:56:31.103716+00
63	Jaeger-LeCoultre	270.6.49	2025-04-08	1	33020.00	33020.00	33020.00	2.4075	2026-02-18 09:56:31.103716+00
64	Jaeger-LeCoultre	Q5273480	2025-04-08	1	57150.00	57150.00	57150.00	2.5028	2026-02-18 09:56:31.103716+00
65	J. Player & Sons	\N	2025-04-08	1	2238000.00	2238000.00	2238000.00	3.1399	2026-02-18 09:56:31.103716+00
66	Kikuchi Nakagawa	\N	2025-04-08	1	64770.00	64770.00	64770.00	2.5246	2026-02-18 09:56:31.103716+00
67	Konstantin Chaykin	\N	2025-04-08	1	44450.00	44450.00	44450.00	2.4592	2026-02-18 09:56:31.103716+00
68	Laurent Ferrier	\N	2025-04-08	1	97790.00	97790.00	97790.00	2.5961	2026-02-18 09:56:31.103716+00
69	Lederer	CIC 9012.60.801	2025-04-08	1	101600.00	101600.00	101600.00	2.6028	2026-02-18 09:56:31.103716+00
70	Longines	6630	2025-04-08	1	44450.00	44450.00	44450.00	2.4592	2026-02-18 09:56:31.103716+00
71	Louis Berthoud	\N	2025-04-08	1	406400.00	406400.00	406400.00	2.8436	2026-02-18 09:56:31.103716+00
72	MB&F	04.TR.GBP	2025-04-08	1	78740.00	78740.00	78740.00	2.5585	2026-02-18 09:56:31.103716+00
73	Ondrej Berkus	\N	2025-04-08	1	69850.00	69850.00	69850.00	2.5377	2026-02-18 09:56:31.103716+00
74	Otsuka Lotec	5	2025-04-08	1	21590.00	21590.00	21590.00	2.3337	2026-02-18 09:56:31.103716+00
75	Patek Philippe	1518	2025-04-08	3	18394000.00	6131333.33	3569000.00	4.7059	2026-02-18 09:56:31.103716+00
76	Patek Philippe	1526	2025-04-08	1	381000.00	381000.00	381000.00	2.8324	2026-02-18 09:56:31.103716+00
77	Patek Philippe	2438/1	2025-04-08	1	889000.00	889000.00	889000.00	2.9796	2026-02-18 09:56:31.103716+00
78	Patek Philippe	2499	2025-04-08	1	1633000.00	1633000.00	1633000.00	3.0852	2026-02-18 09:56:31.103716+00
79	Patek Philippe	2524-1	2025-04-08	1	647700.00	647700.00	647700.00	2.9245	2026-02-18 09:56:31.103716+00
80	Patek Philippe	3424	2025-04-08	1	241300.00	241300.00	241300.00	2.7530	2026-02-18 09:56:31.103716+00
81	Patek Philippe	3424/1	2025-04-08	1	812800.00	812800.00	812800.00	2.9640	2026-02-18 09:56:31.103716+00
82	Patek Philippe	3450	2025-04-08	1	190500.00	190500.00	190500.00	2.7120	2026-02-18 09:56:31.103716+00
83	Patek Philippe	3700/1	2025-04-08	2	292100.00	146050.00	146050.00	3.3862	2026-02-18 09:56:31.103716+00
84	Patek Philippe	3712/1A	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
85	Patek Philippe	3724/4	2025-04-08	1	90170.00	90170.00	90170.00	2.5820	2026-02-18 09:56:31.103716+00
86	Patek Philippe	3970E	2025-04-08	1	381000.00	381000.00	381000.00	2.8324	2026-02-18 09:56:31.103716+00
87	Patek Philippe	3970ER	2025-04-08	1	165100.00	165100.00	165100.00	2.6871	2026-02-18 09:56:31.103716+00
88	Patek Philippe	3971	2025-04-08	1	317500.00	317500.00	317500.00	2.8007	2026-02-18 09:56:31.103716+00
89	Patek Philippe	5004G-015	2025-04-08	1	431800.00	431800.00	431800.00	2.8541	2026-02-18 09:56:31.103716+00
90	Patek Philippe	5004P-033	2025-04-08	1	406400.00	406400.00	406400.00	2.8436	2026-02-18 09:56:31.103716+00
91	Patek Philippe	5050J-027	2025-04-08	1	139700.00	139700.00	139700.00	2.6581	2026-02-18 09:56:31.103716+00
92	Patek Philippe	5180/1G-001	2025-04-08	1	76200.00	76200.00	76200.00	2.5528	2026-02-18 09:56:31.103716+00
93	Patek Philippe	5207P	2025-04-08	1	596900.00	596900.00	596900.00	2.9104	2026-02-18 09:56:31.103716+00
94	Patek Philippe	5270J	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
95	Patek Philippe	534	2025-04-08	1	43180.00	43180.00	43180.00	2.4541	2026-02-18 09:56:31.103716+00
96	Patek Philippe	5370P-001	2025-04-08	1	381000.00	381000.00	381000.00	2.8324	2026-02-18 09:56:31.103716+00
97	Patek Philippe	5372P	2025-04-08	1	381000.00	381000.00	381000.00	2.8324	2026-02-18 09:56:31.103716+00
98	Patek Philippe	5399G-010	2025-04-08	1	107950.00	107950.00	107950.00	2.6133	2026-02-18 09:56:31.103716+00
99	Patek Philippe	5520P-001	2025-04-08	1	152400.00	152400.00	152400.00	2.6732	2026-02-18 09:56:31.103716+00
100	Patek Philippe	5575G-001	2025-04-08	1	82550.00	82550.00	82550.00	2.5667	2026-02-18 09:56:31.103716+00
101	Patek Philippe	565	2025-04-08	1	73660.00	73660.00	73660.00	2.5469	2026-02-18 09:56:31.103716+00
102	Patek Philippe	570	2025-04-08	1	196850.00	196850.00	196850.00	2.7177	2026-02-18 09:56:31.103716+00
103	Patek Philippe	592	2025-04-08	1	444500.00	444500.00	444500.00	2.8591	2026-02-18 09:56:31.103716+00
104	Patek Philippe	5970G-001	2025-04-08	1	209550.00	209550.00	209550.00	2.7285	2026-02-18 09:56:31.103716+00
105	Patek Philippe	5970P-001	2025-04-08	1	254000.00	254000.00	254000.00	2.7619	2026-02-18 09:56:31.103716+00
106	Patek Philippe	5976/1G-001	2025-04-08	1	279400.00	279400.00	279400.00	2.7785	2026-02-18 09:56:31.103716+00
107	Patek Philippe	605	2025-04-08	1	57150.00	57150.00	57150.00	2.5028	2026-02-18 09:56:31.103716+00
108	Patek Philippe	658	2025-04-08	1	190500.00	190500.00	190500.00	2.7120	2026-02-18 09:56:31.103716+00
109	Patek Philippe	ined and enormously collectible pink gold "First Series" perpetual calendar wristwatch with center seconds moonphases, Frecnh import marks and French calendar, possibly the only example known with magnifying glass	2025-04-08	1	965200.00	965200.00	965200.00	2.9938	2026-02-18 09:56:31.103716+00
110	Patek Philippe	ined and the only example known of a pink gold world time wristwatch with flat bezel and tear drop lugs	2025-04-08	1	444500.00	444500.00	444500.00	2.8591	2026-02-18 09:56:31.103716+00
111	Patek Philippe	\N	2025-04-08	3	252730.00	84243.33	91440.00	3.9611	2026-02-18 09:56:31.103716+00
112	Richard Daners for Gübelin	18D	2025-04-08	1	101600.00	101600.00	101600.00	2.6028	2026-02-18 09:56:31.103716+00
113	Richard Daners for Gübelin	\N	2025-04-08	1	53340.00	53340.00	53340.00	2.4908	2026-02-18 09:56:31.103716+00
114	Rolex	116509	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
115	Rolex	116595RBOW	2025-04-08	1	317500.00	317500.00	317500.00	2.8007	2026-02-18 09:56:31.103716+00
116	Rolex	116759SANR	2025-04-08	1	101600.00	101600.00	101600.00	2.6028	2026-02-18 09:56:31.103716+00
117	Rolex	118238	2025-04-08	1	165100.00	165100.00	165100.00	2.6871	2026-02-18 09:56:31.103716+00
118	Rolex	14270	2025-04-08	1	10160.00	10160.00	10160.00	2.2028	2026-02-18 09:56:31.103716+00
119	Rolex	16238	2025-04-08	1	27940.00	27940.00	27940.00	2.3785	2026-02-18 09:56:31.103716+00
120	Rolex	16520	2025-04-08	3	215900.00	71966.67	60960.00	3.9337	2026-02-18 09:56:31.103716+00
121	Rolex	16520, caseback stamped "16500" to the inside	2025-04-08	1	35560.00	35560.00	35560.00	2.4204	2026-02-18 09:56:31.103716+00
122	Rolex	16520 (inside caseback stamped 16500)	2025-04-08	1	203200.00	203200.00	203200.00	2.7232	2026-02-18 09:56:31.103716+00
123	Rolex	16528	2025-04-08	1	60960.00	60960.00	60960.00	2.5140	2026-02-18 09:56:31.103716+00
124	Rolex	16600	2025-04-08	1	177800.00	177800.00	177800.00	2.7000	2026-02-18 09:56:31.103716+00
125	Rolex	18059	2025-04-08	1	1079500.00	1079500.00	1079500.00	3.0133	2026-02-18 09:56:31.103716+00
126	Rolex	18238	2025-04-08	1	48260.00	48260.00	48260.00	2.4734	2026-02-18 09:56:31.103716+00
127	Rolex	18238, caseback stamped 18200	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
128	Rolex	226679TBR	2025-04-08	1	82550.00	82550.00	82550.00	2.5667	2026-02-18 09:56:31.103716+00
129	Rolex	228396TBR	2025-04-08	1	139700.00	139700.00	139700.00	2.6581	2026-02-18 09:56:31.103716+00
130	Rolex	5508	2025-04-08	1	73660.00	73660.00	73660.00	2.5469	2026-02-18 09:56:31.103716+00
131	Rolex	5513	2025-04-08	1	158750.00	158750.00	158750.00	2.6803	2026-02-18 09:56:31.103716+00
132	Rolex	6234	2025-04-08	1	27940.00	27940.00	27940.00	2.3785	2026-02-18 09:56:31.103716+00
133	Rolex	6238	2025-04-08	3	488950.00	162983.33	177800.00	4.0757	2026-02-18 09:56:31.103716+00
134	Rolex	6239	2025-04-08	1	1079500.00	1079500.00	1079500.00	3.0133	2026-02-18 09:56:31.103716+00
135	Rolex	6239, caseback stamped "6242" to the inside	2025-04-08	1	273050.00	273050.00	273050.00	2.7745	2026-02-18 09:56:31.103716+00
136	Rolex	6241	2025-04-08	3	1155700.00	385233.33	254000.00	4.2251	2026-02-18 09:56:31.103716+00
137	Rolex	6263	2025-04-08	4	1772000.00	443000.00	146050.00	4.8994	2026-02-18 09:56:31.103716+00
138	Rolex	6265	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
139	Rolex	6269 inside caseback stamped 6263	2025-04-08	1	1378900.00	1378900.00	1378900.00	3.0558	2026-02-18 09:56:31.103716+00
140	Rolex	6284	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
141	Rolex	6511	2025-04-08	1	80010.00	80010.00	80010.00	2.5613	2026-02-18 09:56:31.103716+00
142	Rolex	6542	2025-04-08	1	127000.00	127000.00	127000.00	2.6415	2026-02-18 09:56:31.103716+00
143	Rolex	8171	2025-04-08	1	254000.00	254000.00	254000.00	2.7619	2026-02-18 09:56:31.103716+00
144	Rolex	971	2025-04-08	1	10795.00	10795.00	10795.00	2.2133	2026-02-18 09:56:31.103716+00
145	Rolex	ined and highly attractive white gold wristwatch with bracelet, center seconds, day, date, diamond-set bezel and dial sector ring, with warranty and presentation box	2025-04-08	1	25400.00	25400.00	25400.00	2.3619	2026-02-18 09:56:31.103716+00
146	Seiko	4520-8020	2025-04-08	1	101600.00	101600.00	101600.00	2.6028	2026-02-18 09:56:31.103716+00
147	Seiko	6139-6010	2025-04-08	1	15240.00	15240.00	15240.00	2.2732	2026-02-18 09:56:31.103716+00
148	Simon Brette	\N	2025-04-08	1	279400.00	279400.00	279400.00	2.7785	2026-02-18 09:56:31.103716+00
149	S. Smith & Son	\N	2025-04-08	1	88900.00	88900.00	88900.00	2.5796	2026-02-18 09:56:31.103716+00
150	Urban Jürgensen	ined pink gold wristwatch with guilloché dial, date, certificate of authenticity and presentation box	2025-04-08	1	63500.00	63500.00	63500.00	2.5211	2026-02-18 09:56:31.103716+00
151	Urban Jürgensen	\N	2025-04-08	3	702945.00	234315.00	60960.00	4.1388	2026-02-18 09:56:31.103716+00
152	Urwerk	UR-103	2025-04-08	1	40640.00	40640.00	40640.00	2.4436	2026-02-18 09:56:31.103716+00
153	Vacheron Constantin	4020T/000R-B654	2025-04-08	1	33020.00	33020.00	33020.00	2.4075	2026-02-18 09:56:31.103716+00
154	Vacheron Constantin	4300V	2025-04-08	1	69850.00	69850.00	69850.00	2.5377	2026-02-18 09:56:31.103716+00
155	Vacheron Constantin	43041	2025-04-08	1	120650.00	120650.00	120650.00	2.6326	2026-02-18 09:56:31.103716+00
156	Vacheron Constantin	43050	2025-04-08	1	114300.00	114300.00	114300.00	2.6232	2026-02-18 09:56:31.103716+00
157	Vacheron Constantin	6111	2025-04-08	1	20320.00	20320.00	20320.00	2.3232	2026-02-18 09:56:31.103716+00
158	Vacheron Constantin	6440Q	2025-04-08	1	24130.00	24130.00	24130.00	2.3530	2026-02-18 09:56:31.103716+00
159	Vianney Halter	\N	2025-04-08	1	50800.00	50800.00	50800.00	2.4823	2026-02-18 09:56:31.103716+00
160	Voutilainen	\N	2025-04-08	1	381000.00	381000.00	381000.00	2.8324	2026-02-18 09:56:31.103716+00
161	Yosuke Sekiguchi	\N	2025-04-08	1	95250.00	95250.00	95250.00	2.5915	2026-02-18 09:56:31.103716+00
\.


--
-- Data for Name: watch_index_market_daily; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.watch_index_market_daily (id, index_date, lot_count, total_value, avg_price, median_price, unique_brands, unique_references, demand_score, created_at) FROM stdin;
1	2025-04-08	187	62579465.00	334649.55	114300.00	54	129	100.8389	2026-02-18 11:32:13.144979+00
\.


--
-- Data for Name: watch_references; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.watch_references (reference_id, model_id, reference_code) FROM stdin;
11	1	116719BLRO
12	2	116506
13	2	116500LN
14	3	5208P
15	3	5270P
16	4	5980/1A
17	4	5712/1A-001
18	4	5711/1A-010
19	4	5711/1A
20	5	26574ST
21	5	16202ST.OO.1240ST.01
22	5	15202ST
23	6	403.035
24	7	Time Zone
25	7	LSLS1A
\.


--
-- Name: auction_events_auction_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auction_events_auction_event_id_seq', 7, true);


--
-- Name: auction_houses_auction_house_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auction_houses_auction_house_id_seq', 1, true);


--
-- Name: auction_lots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auction_lots_id_seq', 602, true);


--
-- Name: brands_brand_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.brands_brand_id_seq', 4, true);


--
-- Name: market_listings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.market_listings_id_seq', 1, false);


--
-- Name: models_model_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.models_model_id_seq', 7, true);


--
-- Name: watch_index_brand_daily_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.watch_index_brand_daily_id_seq', 54, true);


--
-- Name: watch_index_daily_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.watch_index_daily_id_seq', 161, true);


--
-- Name: watch_index_market_daily_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.watch_index_market_daily_id_seq', 1, true);


--
-- Name: watch_references_reference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.watch_references_reference_id_seq', 25, true);


--
-- Name: auction_events auction_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_events
    ADD CONSTRAINT auction_events_pkey PRIMARY KEY (auction_event_id);


--
-- Name: auction_houses auction_houses_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_houses
    ADD CONSTRAINT auction_houses_name_key UNIQUE (name);


--
-- Name: auction_houses auction_houses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_houses
    ADD CONSTRAINT auction_houses_pkey PRIMARY KEY (auction_house_id);


--
-- Name: auction_lots auction_lots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_lots
    ADD CONSTRAINT auction_lots_pkey PRIMARY KEY (id);


--
-- Name: brands brands_brand_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_brand_name_key UNIQUE (brand_name);


--
-- Name: brands brands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brands
    ADD CONSTRAINT brands_pkey PRIMARY KEY (brand_id);


--
-- Name: demand_scores demand_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demand_scores
    ADD CONSTRAINT demand_scores_pkey PRIMARY KEY (snapshot_date, reference_id);


--
-- Name: listings_daily listings_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings_daily
    ADD CONSTRAINT listings_daily_pkey PRIMARY KEY (snapshot_date, reference_id);


--
-- Name: market_listings market_listings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_listings
    ADD CONSTRAINT market_listings_pkey PRIMARY KEY (id);


--
-- Name: market_listings market_listings_url_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.market_listings
    ADD CONSTRAINT market_listings_url_key UNIQUE (url);


--
-- Name: models models_brand_id_model_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT models_brand_id_model_name_key UNIQUE (brand_id, model_name);


--
-- Name: models models_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT models_pkey PRIMARY KEY (model_id);


--
-- Name: auction_lots unique_auction_lot; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_lots
    ADD CONSTRAINT unique_auction_lot UNIQUE (auction_house, auction_id, lot);


--
-- Name: auction_lots unique_url; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_lots
    ADD CONSTRAINT unique_url UNIQUE (url);


--
-- Name: watch_index_brand_daily watch_index_brand_daily_brand_index_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_brand_daily
    ADD CONSTRAINT watch_index_brand_daily_brand_index_date_key UNIQUE (brand, index_date);


--
-- Name: watch_index_brand_daily watch_index_brand_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_brand_daily
    ADD CONSTRAINT watch_index_brand_daily_pkey PRIMARY KEY (id);


--
-- Name: watch_index_daily watch_index_daily_brand_reference_code_index_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_daily
    ADD CONSTRAINT watch_index_daily_brand_reference_code_index_date_key UNIQUE (brand, reference_code, index_date);


--
-- Name: watch_index_daily watch_index_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_daily
    ADD CONSTRAINT watch_index_daily_pkey PRIMARY KEY (id);


--
-- Name: watch_index_market_daily watch_index_market_daily_index_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_market_daily
    ADD CONSTRAINT watch_index_market_daily_index_date_key UNIQUE (index_date);


--
-- Name: watch_index_market_daily watch_index_market_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_index_market_daily
    ADD CONSTRAINT watch_index_market_daily_pkey PRIMARY KEY (id);


--
-- Name: watch_references watch_references_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_references
    ADD CONSTRAINT watch_references_pkey PRIMARY KEY (reference_id);


--
-- Name: watch_references watch_references_reference_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_references
    ADD CONSTRAINT watch_references_reference_code_key UNIQUE (reference_code);


--
-- Name: idx_auction_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auction_brand ON public.auction_lots USING btree (brand);


--
-- Name: idx_auction_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auction_created_at ON public.auction_lots USING btree (created_at DESC);


--
-- Name: idx_auction_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auction_date ON public.auction_lots USING btree (auction_date DESC);


--
-- Name: idx_auction_house; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auction_house ON public.auction_lots USING btree (auction_house);


--
-- Name: idx_auction_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auction_reference ON public.auction_lots USING btree (reference_code);


--
-- Name: idx_brand_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_brand_reference ON public.auction_lots USING btree (brand, reference_code);


--
-- Name: idx_demand_scores_reference_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_demand_scores_reference_date ON public.demand_scores USING btree (reference_id, snapshot_date);


--
-- Name: idx_demand_scores_sellability; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_demand_scores_sellability ON public.demand_scores USING btree (sellability_score DESC);


--
-- Name: idx_listings_reference_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listings_reference_date ON public.listings_daily USING btree (reference_id, snapshot_date);


--
-- Name: idx_market_brand; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_market_brand ON public.market_listings USING btree (brand);


--
-- Name: idx_market_price; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_market_price ON public.market_listings USING btree (price);


--
-- Name: idx_market_reference; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_market_reference ON public.market_listings USING btree (reference_code);


--
-- Name: auction_events auction_events_auction_house_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auction_events
    ADD CONSTRAINT auction_events_auction_house_id_fkey FOREIGN KEY (auction_house_id) REFERENCES public.auction_houses(auction_house_id);


--
-- Name: demand_scores demand_scores_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demand_scores
    ADD CONSTRAINT demand_scores_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.watch_references(reference_id);


--
-- Name: listings_daily listings_daily_reference_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.listings_daily
    ADD CONSTRAINT listings_daily_reference_id_fkey FOREIGN KEY (reference_id) REFERENCES public.watch_references(reference_id);


--
-- Name: models models_brand_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.models
    ADD CONSTRAINT models_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES public.brands(brand_id);


--
-- Name: watch_references watch_references_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.watch_references
    ADD CONSTRAINT watch_references_model_id_fkey FOREIGN KEY (model_id) REFERENCES public.models(model_id);


--
-- PostgreSQL database dump complete
--

\unrestrict 9MQqlcEm0ymzS5JCnddoqZPt7dSfDl5kuifpIKDEFURnbvGCyfCp4dVKN3W0Kx0

