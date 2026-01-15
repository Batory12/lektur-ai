# firestore_manager.py

import os
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional

import firebase_admin
from dotenv import load_dotenv
from firebase_admin import credentials, firestore

from app.exam_schemas import Answer as AnswerSchema
from app.exam_schemas import Exam as ExamSchema
from app.exam_schemas import ExamQuestionLink
from app.exam_schemas import Question as QuestionSchema
from app.schemas import *

load_dotenv()


# ====================================================================
# A. EXAM / QUESTION / ANSWER SCHEMAS (Firestore)
# ====================================================================


# ====================================================================
# B. CLASS MANAGING CONNECTION TO FIRESTORE (CRUD)
# ====================================================================
class FirestoreManager:
    # ⚠️ Change this path to the path to your service account JSON key file ⚠️
    SERVICE_ACCOUNT_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH")

    def __init__(self):
        self.USERS_COLLECTION = "users"
        self.STATS_COLLECTION = "user-all-time-stats"
        self.DAILY_STATS_SUBCOLLECTION = "daily-stats"
        self.HISTORY_SUBCOLLECTION = "history"
        self.SCHOOLS_COLLECTION = "schools"
        self.EXAMS_COLLECTION = "exams"
        self.QUESTIONS_COLLECTION = "questions"
        self.ANSWERS_COLLECTION = "answers"
        self.EXAM_QUESTION_LINKS_COLLECTION = "exam-question-links"

        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(self.SERVICE_ACCOUNT_PATH)
                firebase_admin.initialize_app(cred)

            self.db = firestore.client()
        except Exception as e:
            self.db = None
            raise RuntimeError(
                f"Error initializing Firestore: {e}. Check SERVICE_ACCOUNT_PATH."
            )

    # ---------------------------------
    # CRUD OPERATIONS FOR EXAMS / QUESTIONS / ANSWERS
    # ---------------------------------

    # ➕ Create exam with questions & answers (from extracted JSON)
    def create_exam_with_content(
        self,
        exam: ExamSchema,
        questions: List[QuestionSchema],
        answers: List[AnswerSchema],
    ) -> Optional[str]:
        """
        Stores a single exam document and related questions/answers.

        - Exam is stored in EXAMS_COLLECTION.
        - Each Question is stored in QUESTIONS_COLLECTION.
        - Each Answer is stored in ANSWERS_COLLECTION.
        - Relationships exam <-> question are stored in EXAM_QUESTION_LINKS_COLLECTION.
        - Answer.question_number is expected to match Question.number.
        """
        if not self.db:
            return None

        try:
            batch = self.db.batch()

            # 1. Create exam document
            exam_ref = self.db.collection(self.EXAMS_COLLECTION).document()
            exam_dict = exam.model_dump(exclude_none=True, exclude={"id"})
            batch.set(exam_ref, exam_dict)

            # Helper: map question_number -> AnswerSchema
            answers_by_number: Dict[int, AnswerSchema] = {
                a.question_number: a for a in answers
            }

            # 2. Create questions, answers and links
            for idx, q in enumerate(questions):
                # Question doc
                q_ref = self.db.collection(self.QUESTIONS_COLLECTION).document()
                q_dict = q.model_dump(exclude_none=True, exclude={"id"})
                batch.set(q_ref, q_dict)

                # Link exam <-> question
                link_ref = self.db.collection(
                    self.EXAM_QUESTION_LINKS_COLLECTION
                ).document()
                link = ExamQuestionLink(
                    exam_id=exam_ref.id,
                    question_id=q_ref.id,
                    order=idx + 1,
                )
                batch.set(link_ref, link.model_dump(exclude_none=True, exclude={"id"}))

                # Optional: answer for this question_number
                answer = answers_by_number.get(q.number)
                if answer:
                    a_ref = self.db.collection(self.ANSWERS_COLLECTION).document()
                    a_dict = answer.model_dump(exclude_none=True, exclude={"id"})
                    # also store explicit foreign keys for easier querying
                    a_dict["exam_id"] = exam_ref.id
                    a_dict["question_doc_id"] = q_ref.id
                    batch.set(a_ref, a_dict)

            # 3. Commit batch
            batch.commit()
            return exam_ref.id
        except Exception as e:
            print(f"❌ Error creating exam with content: {e}")
            return None

    # 🔍 Get exam basic data
    def get_exam(self, exam_id: str) -> Optional[ExamSchema]:
        if not self.db:
            return None
        try:
            doc = self.db.collection(self.EXAMS_COLLECTION).document(exam_id).get()
            if doc.exists:
                return ExamSchema(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Error reading exam: {e}")
            return None

    # 🔍 Get questions for exam (ordered)
    def get_exam_questions(self, exam_id: str) -> List[QuestionSchema]:
        if not self.db:
            return []
        try:
            # 1. Get links ordered by 'order'
            links_query = (
                self.db.collection(self.EXAM_QUESTION_LINKS_COLLECTION)
                .where("exam_id", "==", exam_id)
                .order_by("order")
            )
            links_docs = list(links_query.stream())
            question_ids = [
                d.get("question_id") for d in (doc.to_dict() for doc in links_docs)
            ]

            # 2. Fetch questions by ids
            questions: List[QuestionSchema] = []
            for qid in question_ids:
                if not qid:
                    continue
                q_doc = (
                    self.db.collection(self.QUESTIONS_COLLECTION).document(qid).get()
                )
                if q_doc.exists:
                    questions.append(QuestionSchema(**q_doc.to_dict(), doc_id=q_doc.id))

            return questions
        except Exception as e:
            print(f"❌ Error reading exam questions: {e}")
            return []

    # 🔍 Get answers for exam (indexed by question_number)
    def get_exam_answers(self, exam_id: str) -> Dict[int, AnswerSchema]:
        if not self.db:
            return {}
        try:
            query = self.db.collection(self.ANSWERS_COLLECTION).where(
                "exam_id", "==", exam_id
            )
            docs = query.stream()
            result: Dict[int, AnswerSchema] = {}
            for doc in docs:
                data = doc.to_dict()
                try:
                    ans = AnswerSchema(**data, doc_id=doc.id)
                    result[ans.question_number] = ans
                except Exception as model_err:
                    print(f"❌ Error parsing answer document {doc.id}: {model_err}")
            return result
        except Exception as e:
            print(f"❌ Error reading exam answers: {e}")
            return {}

    # ---------------------------------
    # CRUD OPERATIONS FOR EXAMS / QUESTIONS / ANSWERS
    # ---------------------------------

    # ➕ Create exam with questions & answers (from extracted JSON)
    def create_exam_with_content(
        self,
        exam: ExamSchema,
        questions: List[QuestionSchema],
        answers: List[AnswerSchema],
    ) -> Optional[str]:
        """
        Stores a single exam document and related questions/answers.

        - Exam is stored in EXAMS_COLLECTION.
        - Each Question is stored in QUESTIONS_COLLECTION.
        - Each Answer is stored in ANSWERS_COLLECTION.
        - Relationships exam <-> question are stored in EXAM_QUESTION_LINKS_COLLECTION.
        - Answer.question_number is expected to match Question.number.
        """
        if not self.db:
            return None

        try:
            batch = self.db.batch()

            # 1. Create exam document
            exam_ref = self.db.collection(self.EXAMS_COLLECTION).document()
            exam_dict = exam.model_dump(exclude_none=True, exclude={"id"})
            batch.set(exam_ref, exam_dict)

            # Helper: map question_number -> AnswerSchema
            answers_by_number: Dict[int, AnswerSchema] = {
                a.question_number: a for a in answers
            }

            # 2. Create questions, answers and links
            for idx, q in enumerate(questions):
                # Question doc
                q_ref = self.db.collection(self.QUESTIONS_COLLECTION).document()
                q_dict = q.model_dump(exclude_none=True, exclude={"id"})
                batch.set(q_ref, q_dict)

                # Link exam <-> question
                link_ref = self.db.collection(
                    self.EXAM_QUESTION_LINKS_COLLECTION
                ).document()
                link = ExamQuestionLink(
                    exam_id=exam_ref.id,
                    question_id=q_ref.id,
                    order=idx + 1,
                )
                batch.set(link_ref, link.model_dump(exclude_none=True, exclude={"id"}))

                # Optional: answer for this question_number
                answer = answers_by_number.get(q.number)
                if answer:
                    a_ref = self.db.collection(self.ANSWERS_COLLECTION).document()
                    a_dict = answer.model_dump(exclude_none=True, exclude={"id"})
                    # also store explicit foreign keys for easier querying
                    a_dict["exam_id"] = exam_ref.id
                    a_dict["question_doc_id"] = q_ref.id
                    batch.set(a_ref, a_dict)

            # 3. Commit batch
            batch.commit()
            return exam_ref.id
        except Exception as e:
            print(f"❌ Error creating exam with content: {e}")
            return None

    # 🔍 Get exam basic data
    def get_exam(self, exam_id: str) -> Optional[ExamSchema]:
        if not self.db:
            return None
        try:
            doc = self.db.collection(self.EXAMS_COLLECTION).document(exam_id).get()
            if doc.exists:
                return ExamSchema(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Error reading exam: {e}")
            return None

    # 🔍 Get questions for exam (ordered)
    def get_exam_questions(self, exam_id: str) -> List[QuestionSchema]:
        if not self.db:
            return []
        try:
            # 1. Get links ordered by 'order'
            links_query = (
                self.db.collection(self.EXAM_QUESTION_LINKS_COLLECTION)
                .where("exam_id", "==", exam_id)
                .order_by("order")
            )
            links_docs = list(links_query.stream())
            question_ids = [
                d.get("question_id") for d in (doc.to_dict() for doc in links_docs)
            ]

            # 2. Fetch questions by ids
            questions: List[QuestionSchema] = []
            for qid in question_ids:
                if not qid:
                    continue
                q_doc = (
                    self.db.collection(self.QUESTIONS_COLLECTION).document(qid).get()
                )
                if q_doc.exists:
                    questions.append(QuestionSchema(**q_doc.to_dict(), doc_id=q_doc.id))

            return questions
        except Exception as e:
            print(f"❌ Error reading exam questions: {e}")
            return []

    # 🔍 Get answers for exam (indexed by question_number)
    def get_exam_answers(self, exam_id: str) -> Dict[int, AnswerSchema]:
        if not self.db:
            return {}
        try:
            query = self.db.collection(self.ANSWERS_COLLECTION).where(
                "exam_id", "==", exam_id
            )
            docs = query.stream()
            result: Dict[int, AnswerSchema] = {}
            for doc in docs:
                data = doc.to_dict()
                try:
                    ans = AnswerSchema(**data, doc_id=doc.id)
                    result[ans.question_number] = ans
                except Exception as model_err:
                    print(f"❌ Error parsing answer document {doc.id}: {model_err}")
            return result
        except Exception as e:
            print(f"❌ Error reading exam answers: {e}")
            return {}

    # ---------------------------------
    # CRUD OPERATIONS FOR 'users'
    # ---------------------------------

    # ➕ ADD USER (Create)
    def add_user(self, user_data: User) -> Optional[str]:
        if not self.db:
            return None

        current_time_utc = datetime.now(timezone.utc)

        # Convert Pydantic model to a dict, excluding fields that we will overwrite
        data = user_data.model_dump(
            exclude_none=True, exclude={"id", "createdAt", "updatedAt", "lastLoginAt"}
        )

        data["createdAt"] = current_time_utc
        data["updatedAt"] = current_time_utc
        data["lastLoginAt"] = current_time_utc

        try:
            # 1. Create a new empty reference (automatically generates a unique ID)
            new_doc_ref = self.db.collection(self.USERS_COLLECTION).document()

            # 2. Use this reference to write the data (SET operation)
            new_doc_ref.set(data)

            # 3. Return the ID directly from the reference (safe)
            return new_doc_ref.id
        except Exception as e:
            print(f"❌ Error adding user: {e}")
            return None

    # 🔍 GET USER (Read)
    def get_user(self, user_id: str) -> Optional[User]:
        if not self.db:
            return None
        try:
            doc = self.db.collection(self.USERS_COLLECTION).document(user_id).get()
            if doc.exists:
                # Firebase SDK automatically converts Timestamp to Python datetime.
                return User(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Error reading user: {e}")
            return None

    # ✏️ UPDATE USER (Update)
    def update_user(self, user_id: str, update_data: Dict[str, Any]) -> bool:
        if not self.db:
            return False
        try:
            # Set updatedAt field to current UTC datetime
            update_data["updatedAt"] = datetime.now(timezone.utc)
            self.db.collection(self.USERS_COLLECTION).document(user_id).update(
                update_data
            )
            return True
        except Exception as e:
            print(f"❌ Error updating user: {e}")
            return False

    # 🗑️ DELETE USER (Delete)
    def delete_user(self, user_id: str) -> bool:
        if not self.db:
            return False
        try:
            self.db.collection(self.USERS_COLLECTION).document(user_id).delete()
            self.db.collection(self.STATS_COLLECTION).document(user_id).delete()
            return True
        except Exception as e:
            print(f"❌ Error deleting user: {e}")
            return False

    # ---------------------------------
    # CRUD OPERATIONS FOR 'user-all-time-stats'
    # ---------------------------------
    def log_to_file(self, message):
        try:
            with open("/tmp/db_error_log.txt", "a") as f:
                f.write(f"{datetime.now(timezone.utc)} - {message}\n")
        except Exception:
            # Probably no write permission; ignore.
            pass

    def update_stats_after_ex(self, user_id: str, points: int):
        if not self.db:
            return None

        stats = self.get_user_stats(user_id)
        # if stats is None: return

        last_task_date_only = stats.last_task_date.date()
        today_date_only = datetime.now(timezone.utc).date()
        updated_stats = {}

        if last_task_date_only != today_date_only:
            updated_stats["current_streak"] = stats.current_streak + 1

            if stats.current_streak + 1 > stats.longest_streak:
                updated_stats["longest_streak"] = stats.current_streak + 1

        updated_stats["last_task_date"] = datetime.now(timezone.utc)
        updated_stats["points"] = stats.points + points
        updated_stats["total_tasks_done"] = stats.total_tasks_done + 1

        self.db.collection(self.STATS_COLLECTION).document(user_id).update(
            updated_stats
        )

    def add_user_stats(
        self, stats_data: UserAllTimeStats, user_id: str
    ) -> Optional[str]:
        if not self.db:
            return None

        # Ensure last_task_date has UTC timezone set
        if stats_data.last_task_date.tzinfo is None:
            stats_data.last_task_date = stats_data.last_task_date.replace(
                tzinfo=timezone.utc
            )

        data = stats_data.model_dump(exclude_none=True, exclude={"id"})
        try:
            if user_id:
                # Use the provided ID
                self.db.collection(self.STATS_COLLECTION).document(user_id).set(data)
                return user_id
            else:
                # Generate a new unique document ID and use SET
                new_doc_ref = self.db.collection(self.STATS_COLLECTION).document()
                new_doc_ref.set(data)
                return new_doc_ref.id
        except Exception as e:
            print(f"❌ Error adding stats: {e}")
            return None

    # 🔍 GET STATS (Read)
    def get_user_stats(self, user_id: str) -> Optional[UserAllTimeStats]:
        if not self.db:
            return None
        try:
            doc = self.db.collection(self.STATS_COLLECTION).document(user_id).get()
            if doc.exists:
                return UserAllTimeStats(**doc.to_dict(), doc_id=doc.id)
            else:
                new_stats = UserAllTimeStats(
                    current_streak=0,
                    longest_streak=0,
                    last_task_date=datetime(
                        1970, 1, 1, tzinfo=timezone.utc
                    ),  # Very old date as default
                    total_tasks_done=0,
                    points=0
                )
                self.add_user_stats(new_stats, user_id)
                return new_stats
        except Exception as e:
            print(f"❌ Error reading stats: {e}")
            return None
        
    def get_daily_stats(self, user_name: str, date_param: datetime):
        if not self.db: return None
        try:
            date_id = date_param.strftime("%Y-%m-%d")
            stats_coll = (self.db.collection(self.STATS_COLLECTION)
                .document(user_name)
                .collection(self.DAILY_STATS_SUBCOLLECTION))
            doc_ref = stats_coll.document(date_id)
            doc = doc_ref.get()

            if doc.exists:
                return UserDailyStats(**doc.to_dict(), doc_id=doc.id)
            else:
                new_stats = UserDailyStats(points=0)
                doc_ref.set(new_stats.model_dump(exclude_none=True, exclude={"id"}))
                
                all_stats_query = stats_coll.order_by(
                    "__name__", 
                    direction=firestore.Query.DESCENDING
                ).get()

                if len(all_stats_query) > 10:
                    # Documents with index 10 and above should be deleted
                    docs_to_delete = all_stats_query[10:]
                    for old_doc in docs_to_delete:
                        old_doc.reference.delete()
                    print(f"🗑️ Deleted {len(docs_to_delete)} old entries for {user_name}")

                return UserDailyStats(points=0, doc_id=date_id)
        
        except Exception as e:
            print(f"❌ Error reading daily stats: {e}")
            return None
    
    def get_last_ten_stats(self, user_name: str) -> List[UserDailyStats]:
        if not self.db:
            return []

        try:
            today_date = datetime.now(timezone.utc)
            self.get_daily_stats(user_name, today_date)

            stats_coll = (self.db.collection(self.STATS_COLLECTION)
                          .document(user_name)
                          .collection(self.DAILY_STATS_SUBCOLLECTION))

            docs = stats_coll.get()
            
            db_results = {doc.id: doc.to_dict().get("points", 0) for doc in docs}

            final_stats: List[UserDailyStats] = []
            
            for i in range(10):
                current_date = (today_date - timedelta(days=i)).strftime("%Y-%m-%d")
                
                points = db_results.get(current_date, 0)
                
                final_stats.append(
                    UserDailyStats(points=points, doc_id=current_date)
                )

            final_stats.reverse() 

            return final_stats

        except Exception as e:
            print(f"❌ Error while getting stats for {user_name}: {e}")
            return []
        
    def update_daily_stats(self, user_name: str, points: int):
        if not self.db: 
            return None
        
        try:
            date_id = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            stats_coll = (self.db.collection(self.STATS_COLLECTION)
                        .document(user_name)
                        .collection(self.DAILY_STATS_SUBCOLLECTION))
            
            doc_ref = stats_coll.document(date_id)

            data = {
                "points": firestore.Increment(points),
            }
            doc_ref.set(data, merge=True)

            all_stats_query = stats_coll.order_by(
                "__name__", 
                direction=firestore.Query.DESCENDING
            ).get()

            if len(all_stats_query) > 10:
                docs_to_delete = all_stats_query[10:]
                for old_doc in docs_to_delete:
                    old_doc.reference.delete()
                print(f"🗑️ Deleted {len(docs_to_delete)} old entries for {user_name}")

        except Exception as e:
            print(f"❌ Error while updating points: {e}")
    
    # returns a list of dialy average points for a school/class from last ten days
    def get_daily_avg(self, school_name: str, city: str, class_name: Optional[str]) -> List[AvgDailyScores]:
        try:
            
            if class_name is None:
                users_query = (
                    self.db.collection(self.USERS_COLLECTION)
                    .where("city", "==", city)
                    .where("school", "==", school_name)
                )
            else:
                users_query = (
                    self.db.collection(self.USERS_COLLECTION)
                    .where("city", "==", city)
                    .where("school", "==", school_name)
                    .where("className", "==", class_name)
                )
            
            users_docs = users_query.get()
          
            if not users_docs:
                return [AvgDailyScores(avg_points=0.0) for _ in range(10)]

            user_ids = [doc.id for doc in users_docs]
            num_users = len(user_ids)

            today = datetime.now(timezone.utc).date()
            date_ids = [(today - timedelta(days=i)).strftime("%Y-%m-%d") for i in range(10)]
            date_ids.reverse()

            final_results: List[AvgDailyScores] = []

            for date_id in date_ids:
                refs = [
                    self.db.collection(self.STATS_COLLECTION)
                    .document(u_id)
                    .collection(self.DAILY_STATS_SUBCOLLECTION)
                    .document(date_id)
                    for u_id in user_ids
                ]

                docs = self.db.get_all(refs)
                
                total_points_for_day = 0
                for doc in docs:
                    if doc.exists:
                        total_points_for_day += doc.to_dict().get("points", 0)
                
                avg = float(total_points_for_day / num_users) if num_users > 0 else 0.0
                
                final_results.append(AvgDailyScores(avg_points=round(avg, 2)))

            return final_results

        except Exception as e:
            print(f"❌ Error while calculating averages (AvgDailyScores): {e}")
            return [AvgDailyScores(avg_points=0.0) for _ in range(10)]

    def avg_scores(self, school_name: str, city: str, class_name: Optional[str]):
        try:
            if class_name is None:
                users_query = (
                    self.db.collection(self.USERS_COLLECTION)
                    .where("city", "==", city)
                    .where("school", "==", school_name)
                )
            else:
                users_query = (
                    self.db.collection(self.USERS_COLLECTION)
                    .where("city", "==", city)
                    .where("school", "==", school_name)
                    .where("className", "==", class_name)
                )

            users_docs = users_query.get()

            if not users_docs:
                print("Users not found.")
                return 0.0, 0.0

            user_ids = [doc.id for doc in users_docs]
            print(f"Found {len(user_ids)} users.")

        except Exception as e:
            print(f"Error while fetching student IDs from the 'users' collection: {e}")
            return 0.0, 0.0

        total_points = 0
        total_streak = 0
        valid_points_count = 0
        valid_streak_count = 0

        # NOTE: Firestore 'in' query (documents by ID) has a limit of 10 elements.
        # For a larger number of students, IDs must be split into batches of max 10.
        batch_size = 10

        for i in range(0, len(user_ids), batch_size):
            batch_ids = user_ids[i : i + batch_size]

            try:
                # Use field path 'document_id()' and the 'in' operator
                stats_query = self.db.collection(self.STATS_COLLECTION).where(
                    "__name__", "in", batch_ids
                )
                stats_docs = stats_query.get()

                for doc in stats_docs:
                    data = doc.to_dict()

                    if data and isinstance(data.get("points"), (int)):
                        total_points += data["points"]
                        valid_points_count += 1
                    else:
                        print(
                            f"Warning: Stats document for ID {doc.id} does not have a valid 'points' field. Skipping."
                        )

                    if data and isinstance(data.get("current_streak"), (int)):
                        total_streak += data["current_streak"]
                        valid_streak_count += 1
                    else:
                        print(
                            f"Warning: Stats document for ID {doc.id} does not have a valid 'current_streak' field. Skipping."
                        )

            except Exception as e:
                print(f"Error while fetching stats for ID batch: {e}")

        if valid_streak_count == 0:
            print("No valid streak data found to compute the average.")
            average_streak = 0.0
        else:
            average_streak = total_streak / valid_streak_count

        if valid_points_count == 0:
            print("No valid point data found to compute the average.")
            average_points = 0.0
        else:
            average_points = total_points / valid_points_count

        return average_points, average_streak

    # ---------------------------------
    # CRUD OPERATIONS FOR 'history' SUBCOLLECTION
    # ---------------------------------

    # ➕ Add History Entry (Create)
    def add_history_entry(
        self, user_id: str, entry_data: UserHistoryEntry
    ) -> Optional[str]:
        if not self.db:
            return None
        data = entry_data.model_dump(exclude_none=True)

        try:
            # 1. Get reference to the 'history' subcollection
            history_collection_ref = (
                self.db.collection(self.STATS_COLLECTION)
                .document(user_id)
                .collection(self.HISTORY_SUBCOLLECTION)
            )

            # 2. Generate a new document reference (with unique ID) in the subcollection
            new_doc_ref = history_collection_ref.document()

            # 3. Use SET on the new reference
            new_doc_ref.set(data)

            # 4. Return ID directly from the reference (safe)
            return new_doc_ref.id

        except Exception as e:
            print(f"❌ Error adding history entry: {e}")
            return None

    def save_readings_to_history(
        self, user_id: str, submission: ReadingExerciseSubmit, points: int, eval: str
    ):
        raw_data = {}
        raw_data["date"] = datetime.now(timezone.utc)
        raw_data["eval"] = eval
        raw_data["points"] = points
        raw_data["question"] = submission.excercise_text
        raw_data["response"] = submission.user_answer
        raw_data["type"] = "reading"
        try:
            new_data = UserHistoryEntry(**raw_data)
            self.add_history_entry(user_id, new_data)
            return None
        except Exception as e:
            print(f"Error while creating UserHistoryEntry: {e}")

    def save_matura_ex_to_history(
        self, user_id: str, question: str, answer: str, points: int, eval: str
    ):
        raw_data = {}
        raw_data["date"] = datetime.now(timezone.utc)
        raw_data["eval"] = eval
        raw_data["points"] = points
        raw_data["question"] = question
        raw_data["response"] = answer
        raw_data["type"] = "reading"
        try:
            new_data = UserHistoryEntry(**raw_data)
            self.add_history_entry(user_id, new_data)
            return None
        except Exception as e:
            print(f"Error while creating UserHistoryEntry: {e}")

    # 🔍 Get History Entries (Read)
    def get_history_by_range(
        self,
        stat_id: str,
        type_filter: str,
        sort_by: str = "date",
        from_pos: int = 1,  # e.g. 1
        to_pos: int = 10,  # e.g. 10
    ) -> List[UserHistoryEntry]:
        if not self.db:
            return []
        entries: List[UserHistoryEntry] = []

        try:
            history_ref = (
                self.db.collection(self.STATS_COLLECTION)
                .document(stat_id)
                .collection(self.HISTORY_SUBCOLLECTION)
            )

            # --- COMPUTATION LOGIC ---
            # If from_pos = 1, we skip nothing (offset = 0)
            offset_value = max(0, from_pos - 1)

            # Number of items to fetch is the difference of positions + 1
            # Example: from 1 to 10 -> (10 - 1) + 1 = 10 items
            limit_value = to_pos - from_pos + 1

            if limit_value <= 0:
                return []

            # --- BUILDING THE QUERY ---
            # 1. Sort (sort first, then slice the range)
            query = history_ref.order_by(sort_by, direction=firestore.Query.DESCENDING)

            # 2. Filter (optional)
            if type_filter:
                query = query.where("type", "==", type_filter)

            # 3. Slice the from-to range
            query = query.offset(offset_value).limit(limit_value)

            # --- FETCHING ---
            docs = query.stream()

            for doc in docs:
                data = doc.to_dict()
                entries.append(UserHistoryEntry(**data, doc_id=doc.id))

            return entries

        except Exception as e:
            print(f"❌ Error in get_history_by_range: {e}")
            return []

    def get_history_entries(self, stat_id: str) -> List[UserHistoryEntry]:
        if not self.db:
            return []
        entries = []
        try:
            history_ref = (
                self.db.collection(self.STATS_COLLECTION)
                .document(stat_id)
                .collection(self.HISTORY_SUBCOLLECTION)
            )

            docs = history_ref.stream()

            for doc in docs:
                entries.append(UserHistoryEntry(**doc.to_dict(), doc_id=doc.id))

            return entries
        except Exception as e:
            print(f"❌ Error reading history: {e}")
            return []

    # 🗑️ Delete History Entry (Delete)
    def delete_history_entry(self, stat_id: str, history_id: str) -> bool:
        if not self.db:
            return False
        try:
            (
                self.db.collection(self.STATS_COLLECTION)
                .document(stat_id)
                .collection(self.HISTORY_SUBCOLLECTION)
                .document(history_id)
                .delete()
            )
            return True
        except Exception as e:
            print(f"❌ Error deleting history entry: {e}")
            return False

    # ---------------------------------
    # OPERATIONS FOR 'schools'
    # ---------------------------------

    # Helper function to generate prefix search range (without lowercasing)
    def _get_prefix_range(self, phrase: str) -> tuple[str, str]:
        """Creates a query range to search prefixes in Firestore (Case-Sensitive)."""

        # Search phrase is used WITHOUT converting to lowercase
        start = phrase

        # Generate the end of the range. E.g. for 'Wroc' end becomes 'Wrod'
        # This ensures we only find documents that START with 'Wroc'.
        end = start[:-1] + chr(ord(start[-1]) + 1) if start else " "

        return start, end

    # 🔍 1. Search by City (Case-Sensitive Prefix Search)
    def get_schools_by_city(self, city_phrase: str) -> List[School]:
        if not self.db or not city_phrase:
            # When phrase is empty, still return everything (or none, depending on expected behavior)
            return self.get_all_schools()

        try:
            start, end = self._get_prefix_range(city_phrase)

            query = (
                self.db.collection(self.SCHOOLS_COLLECTION)
                .where("City", ">=", start)
                .where("City", "<", end)
            )

            docs = query.stream()
            return [School(**doc.to_dict(), doc_id=doc.id) for doc in docs]

        except Exception as e:
            print(f"❌ Error reading schools by city: {e}")
            return []

    # 🔍 2. Search by Name (Case-Sensitive Prefix Search)
    def get_schools_by_name(self, name_phrase: str) -> List[School]:
        if not self.db or not name_phrase:
            return self.get_all_schools()

        try:
            start, end = self._get_prefix_range(name_phrase)

            query = (
                self.db.collection(self.SCHOOLS_COLLECTION)
                .where("Name", ">=", start)
                .where("Name", "<", end)
            )

            docs = query.stream()
            return [School(**doc.to_dict(), doc_id=doc.id) for doc in docs]

        except Exception as e:
            print(f"❌ Error reading schools by name: {e}")
            return []

    # QUESTION DATA BASE

    def get_question_text_by_id(self, question_id: str) -> str | None:
        try:
            doc_ref = self.collection(self.QUESTIONS_COLLECTION).document(question_id)

            doc = doc_ref.get()

            if doc.exists:
                data = doc.to_dict()

                if data and "text" in data:
                    return data["text"]
                else:
                    return None
            else:
                print(
                    f"Error: Document with ID '{question_id}' was not found in the 'questions' collection."
                )
                return None

        except Exception as e:
            print(f"An error occurred while fetching data: {e}")
            return None
