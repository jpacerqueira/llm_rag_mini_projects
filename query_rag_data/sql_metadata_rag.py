import streamlit as st
import psycopg2
import duckdb
import trino
from langchain_ollama import OllamaLLM
from langchain_community.vectorstores import FAISS
from langchain_ollama import OllamaEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import RetrievalQA
import os
from dotenv import load_dotenv
from typing import Dict, Any, List
import time

# Load environment variables
load_dotenv()

# Database connection parameters
DB_CONFIGS = {
    'postgres': {
        'dbname': os.getenv('POSTGRES_DB', 'cloud_risk_portal_rag_data'),
        'user': os.getenv('POSTGRES_USER', 'postgres'),
        'password': os.getenv('POSTGRES_PASSWORD', 'password'),
        'host': os.getenv('POSTGRES_HOST', '0.0.0.0'),
        'port': os.getenv('POSTGRES_PORT', '5432')
    },
    'duckdb': {
        'path': 'duckdb_data/cloud_risk_portal.duckdb'
    },
    'trino': {
        'host': os.getenv('TRINO_HOST', 'trinodb'),
        'port': os.getenv('TRINO_PORT', 8080),
        'user': os.getenv('TRINO_USER', 'trino'),
        'password': os.getenv('TRINO_PASSWORD', ''),
        'catalog': os.getenv('TRINO_CATALOG', 'hive'),
        'schema': os.getenv('TRINO_SCHEMA', 'cloud_risk_portal_rag_data'),
        'http_scheme': 'http',
        'verify': False
    }
}

def get_database_metadata(db_type: str) -> str:
    """Fetch metadata about all tables in the database based on the selected type."""
    metadata = []
    
    if db_type == 'postgres':
        conn = psycopg2.connect(**DB_CONFIGS['postgres'])
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT table_schema, table_name, column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            ORDER BY table_schema, table_name, ordinal_position;
        """)
        
        for row in cursor.fetchall():
            schema, table, column, data_type, nullable = row
            metadata.append(f"Table: {schema}.{table}\nColumn: {column}\nType: {data_type}\nNullable: {nullable}\n")
        
        cursor.close()
        conn.close()
    
    elif db_type == 'duckdb':
        conn = duckdb.connect(DB_CONFIGS['duckdb']['path'])
        
        # Get tables using DuckDB's information schema
        tables = conn.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'main'
        """).fetchall()
        
        for table in tables:
            table_name = table[0]
            columns = conn.execute(f"""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_name = '{table_name}'
                ORDER BY ordinal_position
            """).fetchall()
            
            for col in columns:
                name, type_, nullable = col
                metadata.append(f"Table: {table_name}\nColumn: {name}\nType: {type_}\nNullable: {nullable}\n")
        
        conn.close()
    
    elif db_type == 'trino':
        max_retries = 3
        retry_delay = 5
        
        for attempt in range(max_retries):
            try:
                conn = trino.dbapi.connect(
                    host=DB_CONFIGS['trino']['host'],
                    port=DB_CONFIGS['trino']['port'],
                    user=DB_CONFIGS['trino']['user'],
                    password=DB_CONFIGS['trino']['password'],
                    catalog=DB_CONFIGS['trino']['catalog'],
                    schema=DB_CONFIGS['trino']['schema'],
                    http_scheme=DB_CONFIGS['trino']['http_scheme'],
                    verify=DB_CONFIGS['trino']['verify']
                )
                cursor = conn.cursor()
                
                cursor.execute("SHOW TABLES")
                tables = cursor.fetchall()
                
                for table in tables:
                    table_name = table[0]
                    cursor.execute(f"DESCRIBE {table_name}")
                    columns = cursor.fetchall()
                    for col in columns:
                        name, type_, extra = col
                        metadata.append(f"Table: {table_name}\nColumn: {name}\nType: {type_}\n")
                
                cursor.close()
                conn.close()
                break
            except Exception as e:
                if attempt < max_retries - 1:
                    st.warning(f"Connection attempt {attempt + 1} failed. Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                else:
                    st.error(f"Failed to connect to Trino after {max_retries} attempts: {str(e)}")
                    raise
    
    return "\n".join(metadata)

def create_rag_chain(db_type: str):
    """Create a RAG chain for querying the database metadata."""
    # Get database metadata
    metadata_text = get_database_metadata(db_type)
    
    # Split the text into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )
    texts = text_splitter.split_text(metadata_text)
    
    # Create embeddings
    base_url = os.getenv('OLLAMA_HOST', 'http://ollama_rag:11434')
    embeddings = OllamaEmbeddings(base_url=base_url, model="llama3.2")
    
    # Create vector store
    vectorstore = FAISS.from_texts(texts, embeddings)
    
    # Create LLM with base_url configuration
    llm = OllamaLLM(model="llama3.2", base_url=base_url)
    
    # Create RAG chain
    qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",
        retriever=vectorstore.as_retriever()
    )
    
    return qa_chain

def main():
    st.title("SQL Database Metadata Query Assistant")
    st.write("Ask questions about the database schema and get answers powered by RAG!")
    
    # Database type selection
    db_type = st.selectbox(
        "Select Database Type:",
        ["postgres", "duckdb", "trino"],
        index=0
    )
    
    # Initialize session state for the QA chain
    if 'qa_chain' not in st.session_state or st.session_state.current_db_type != db_type:
        with st.spinner("Initializing RAG system..."):
            st.session_state.qa_chain = create_rag_chain(db_type)
            st.session_state.current_db_type = db_type
    
    # User input
    user_question = st.text_input(
        f"Ask a question about the {db_type} database schema:",
        placeholder=f"e.g., What tables are in the {db_type} database?"
    )
    
    if user_question:
        with st.spinner("Thinking..."):
            try:
                response = st.session_state.qa_chain.invoke({"query": user_question})
                st.write("Answer:")
                st.write(response["result"])
            except Exception as e:
                st.error(f"An error occurred: {str(e)}")
    
    # Add a button to refresh the metadata
    if st.button("Refresh Database Metadata"):
        with st.spinner("Refreshing metadata..."):
            st.session_state.qa_chain = create_rag_chain(db_type)
        st.success("Metadata refreshed successfully!")

if __name__ == "__main__":
    main() 