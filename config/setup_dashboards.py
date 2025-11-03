"""
Auto-setup Metabase dashboards on first run
"""
import requests
import os
import json
import time
import sys

BASE_URL = "http://localhost:3000"

def wait_for_metabase():
    """Wait for Metabase to be ready"""
    print("⏳ Waiting for Metabase API...")
    max_attempts = 60
    for attempt in range(max_attempts):
        try:
            r = requests.get(f"{BASE_URL}/api/health", timeout=5)
            if r.status_code == 200:
                print("✅ Metabase API is ready")
                return True
        except Exception as e:
            pass
        time.sleep(5)
    print("❌ Timeout waiting for Metabase")
    return False

def setup_metabase():
    """Setup Metabase with admin user and database"""
    
    if not wait_for_metabase():
        return False
    
    session = requests.Session()
    
    # Check if setup is needed
    try:
        props = requests.get(f"{BASE_URL}/api/session/properties").json()
        setup_token = props.get("setup-token")
    except Exception as e:
        print(f"❌ Error checking setup status: {e}")
        return False
    
    if setup_token:
        print("🆕 First time setup - Creating admin user...")
        
        # First time setup
        setup_data = {
            "token": setup_token,
            "user": {
                "email": os.getenv("MB_ADMIN_EMAIL", "admin@example.com"),
                "password": os.getenv("MB_ADMIN_PASSWORD", "SecurePassword123!"),
                "first_name": os.getenv("MB_ADMIN_FIRST_NAME", "Admin"),
                "last_name": os.getenv("MB_ADMIN_LAST_NAME", "User")
            },
            "prefs": {
                "site_name": "Financial Monitoring System",
                "allow_tracking": False
            }
        }
        
        try:
            r = session.post(f"{BASE_URL}/api/setup", json=setup_data)
            r.raise_for_status()
            token = r.json()["id"]
            print(f"✅ Admin user created: {setup_data['user']['email']}")
        except Exception as e:
            print(f"❌ Setup failed: {e}")
            return False
    else:
        print("🔐 Logging in to existing setup...")
        # Login to existing setup
        try:
            r = session.post(f"{BASE_URL}/api/session", json={
                "username": os.getenv("MB_ADMIN_EMAIL", "admin@example.com"),
                "password": os.getenv("MB_ADMIN_PASSWORD", "SecurePassword123!")
            })
            r.raise_for_status()
            token = r.json()["id"]
            print("✅ Logged in successfully")
        except Exception as e:
            print(f"⚠️  Login failed: {e}")
            print("   You'll need to configure manually")
            return False
    
    # Set session token
    session.headers.update({"X-Metabase-Session": token})
    
    # Add DuckDB database
    print("📊 Adding DuckDB database...")
    db_config = {
        "engine": "duckdb",
        "name": "Financial Data",
        "details": {
            "db": "/data/dbt_project.duckdb",
            "read-only": True,
            "old_implicit_casting": True
        }
    }
    
    try:
        r = session.post(f"{BASE_URL}/api/database", json=db_config)
        r.raise_for_status()
        db_id = r.json()["id"]
        print(f"✅ Database added (ID: {db_id})")
        
        # Trigger schema sync
        print("🔄 Syncing database schema...")
        session.post(f"{BASE_URL}/api/database/{db_id}/sync_schema")
        print("✅ Schema sync initiated")
        
    except Exception as e:
        print(f"⚠️  Database setup failed: {e}")
        print("   You can add it manually: /data/dbt_project.duckdb")
    
    # Create a simple dashboard if config exists
    dashboard_config_path = "/config/dashboard_config.json"
    if os.path.exists(dashboard_config_path):
        print("🎨 Creating dashboards from config...")
        try:
            with open(dashboard_config_path) as f:
                config = json.load(f)
            
            # Create dashboard
            dashboard = {
                "name": config.get("name", "Financial Overview"),
                "description": config.get("description", "Main financial monitoring dashboard")
            }
            r = session.post(f"{BASE_URL}/api/dashboard", json=dashboard)
            r.raise_for_status()
            dashboard_id = r.json()["id"]
            print(f"✅ Dashboard created (ID: {dashboard_id})")
            
            # Add cards if defined
            for card_config in config.get("cards", []):
                try:
                    card_config["dataset_query"]["database"] = db_id
                    card = {
                        "name": card_config["name"],
                        "dataset_query": card_config["dataset_query"],
                        "display": card_config.get("display", "table"),
                        "visualization_settings": card_config.get("visualization_settings", {})
                    }
                    r = session.post(f"{BASE_URL}/api/card", json=card)
                    r.raise_for_status()
                    card_id = r.json()["id"]
                    
                    # Add to dashboard
                    session.post(f"{BASE_URL}/api/dashboard/{dashboard_id}/cards", json={
                        "cardId": card_id,
                        "sizeX": card_config.get("sizeX", 4),
                        "sizeY": card_config.get("sizeY", 4),
                        "row": card_config.get("row", 0),
                        "col": card_config.get("col", 0)
                    })
                    print(f"   ✅ Added card: {card_config['name']}")
                except Exception as e:
                    print(f"   ⚠️  Failed to add card: {e}")
            
            print(f"✅ Dashboard ready: {BASE_URL}/dashboard/{dashboard_id}")
            
        except Exception as e:
            print(f"⚠️  Dashboard creation failed: {e}")
    
    print("\n🎉 Setup complete!")
    print(f"📍 Access your dashboard at: {BASE_URL}")
    print(f"👤 Login: {os.getenv('MB_ADMIN_EMAIL', 'matthewchan193@gmail.com')}")
    
    return True

if __name__ == "__main__":
    try:
        success = setup_metabase()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        sys.exit(1)
