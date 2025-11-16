from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
import uvicorn

app = FastAPI()

class Task(BaseModel):
    id: int
    title: str
    description: str
    priority: int  # 1-High, 2-Medium, 3-Low
    context: str

# In-memory storage for simplicity
tasks = []

@app.post('/tasks/', response_model=Task)
async def create_task(task: Task):
    tasks.append(task)
    return task

@app.get('/tasks/', response_model=List[Task])
async def get_tasks():
    # Prioritizing tasks based on context (simple example)
    sorted_tasks = sorted(tasks, key=lambda x: x.priority)
    return sorted_tasks

@app.delete('/tasks/{task_id}', response_model=Task)
async def delete_task(task_id: int):
    global tasks
    task = next((task for task in tasks if task.id == task_id), None)
    if task is None:
        raise HTTPException(status_code=404, detail='Task not found')

    tasks = [t for t in tasks if t.id != task_id]
    return task

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=8000)