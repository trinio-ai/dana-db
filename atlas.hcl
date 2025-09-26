# Atlas configuration for DANA database migrations
# This file defines the database schema management configuration

env "local" {
  # Local development environment using local Atlas CLI
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@localhost:5432/dana?sslmode=disable"
  dev = "postgresql://dana_user:dana_password@localhost:5432/atlas_dev?sslmode=disable"

  migration {
    dir = "file://migrations"
  }

  format {
    migrate {
      diff = "{{ sql . \"  \" }}"
    }
  }
}

env "docker" {
  # Docker environment for containerized development
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@postgres:5432/dana?sslmode=disable"
  dev = "postgresql://dana_user:dana_password@postgres:5432/dana_dev?sslmode=disable"

  migration {
    dir = "file://migrations"
  }

  format {
    migrate {
      diff = "{{ sql . \"  \" }}"
    }
  }

  diff {
    skip {
      drop_schema = true
      drop_column = true
    }
  }
}

env "test" {
  # Test environment
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@postgres:5432/dana_test?sslmode=disable"

  migration {
    dir = "file://migrations"
  }
}

env "production" {
  # Production environment (credentials should be provided via environment variables)
  src = "file://schema.sql"
  url = "${DATABASE_URL}"

  migration {
    dir = "file://migrations"
  }

  format {
    migrate {
      diff = "{{ sql . \"  \" }}"
    }
  }
}

env "existing" {
  # Use existing database with extensions already installed
  src = "file://schema.sql"
  url = "postgresql://dana_user:dana_password@localhost:5432/dana?sslmode=disable"
  dev = "postgresql://dana_user:dana_password@localhost:5432/dana_dev?sslmode=disable"

  migration {
    dir = "file://migrations"
  }

  format {
    migrate {
      diff = "{{ sql . \"  \" }}"
    }
  }
}