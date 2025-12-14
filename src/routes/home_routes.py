"""
Home routes for the python development environment API
"""

from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "python development environment API is running"}
