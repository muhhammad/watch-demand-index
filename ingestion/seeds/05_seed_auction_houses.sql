INSERT INTO auction_houses (name, website)
VALUES ('Phillips', 'https://www.phillips.com')
ON CONFLICT (name) DO NOTHING;