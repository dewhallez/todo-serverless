// frontend/script.js

// --- Configuration (These are now global variables set by index.html) ---
// Variables like API_GATEWAY_URL, USER_POOL_ID, USER_POOL_CLIENT_ID, AWS_REGION
// are expected to be defined in a script block in index.html BEFORE this script loads.

// --- DOM Elements ---
const messageBox = document.getElementById('message-box');
const authSection = document.getElementById('auth-section');
const appSection = document.getElementById('app-section');

const signUpForm = document.getElementById('sign-up-form');
const signUpEmailInput = document.getElementById('signup-email');
const signUpPasswordInput = document.getElementById('signup-password');
const signUpButton = document.getElementById('signup-button');
const showSignInButton = document.getElementById('show-signin');

const confirmSignUpForm = document.getElementById('confirm-signup-form');
const confirmEmailDisplay = document.getElementById('confirm-email-display');
const confirmCodeInput = document.getElementById('confirm-code');
const confirmSignUpButton = document.getElementById('confirm-signup-button');

const signInForm = document.getElementById('sign-in-form');
const signInEmailInput = document.getElementById('signin-email');
const signInPasswordInput = document.getElementById('signin-password');
const signInButton = document.getElementById('signin-button');
const showSignUpButton = document.getElementById('show-signup');

const usernameDisplay = document.getElementById('username-display');
const signOutButton = document.getElementById('signout-button');
const newTodoTaskInput = document.getElementById('new-todo-task');
const addTodoButton = document.getElementById('add-todo-button');
const noTodosMessage = document.getElementById('no-todos-message');
const todoList = document.getElementById('todo-list');

let currentEmail = ''; // To store email during sign-up process

// --- Message Display Function ---
function showMessage(text, isError = false) {
    messageBox.textContent = text;
    messageBox.classList.remove('hidden', 'bg-blue-50', 'text-blue-700', 'border-blue-200', 'bg-red-50', 'text-red-700', 'border-red-200');
    if (isError) {
        messageBox.classList.add('bg-red-50', 'text-red-700', 'border-red-200');
    } else {
        messageBox.classList.add('bg-blue-50', 'text-blue-700', 'border-blue-200');
    }
    messageBox.classList.remove('hidden');
    setTimeout(() => {
        messageBox.classList.add('hidden');
    }, 5000); // Hide after 5 seconds
}

// --- UI State Management ---
function showAuthSection(formToShow) {
    authSection.classList.remove('hidden');
    appSection.classList.add('hidden');

    signUpForm.classList.add('hidden');
    confirmSignUpForm.classList.add('hidden');
    signInForm.classList.add('hidden');

    if (formToShow === 'signup') {
        signUpForm.classList.remove('hidden');
    } else if (formToShow === 'confirmSignUp') {
        confirmSignUpForm.classList.remove('hidden');
        confirmEmailDisplay.textContent = currentEmail;
    } else if (formToShow === 'signin') {
        signInForm.classList.remove('hidden');
    }
}

function showAppSection(user) {
    authSection.classList.add('hidden');
    appSection.classList.remove('hidden');
    usernameDisplay.textContent = user.attributes?.email || user.username;
    fetchTodos();
}

// --- AWS Amplify Configuration ---
function configureAmplify() {
    // Check if Amplify and configuration variables are available
    if (window.Amplify && window.Auth && typeof API_GATEWAY_URL !== 'undefined' && typeof USER_POOL_ID !== 'undefined' && typeof USER_POOL_CLIENT_ID !== 'undefined' && typeof AWS_REGION !== 'undefined') {
        window.Amplify.configure({
            Auth: {
                region: AWS_REGION,
                userPoolId: USER_POOL_ID,
                userPoolWebClientId: USER_POOL_CLIENT_ID,
            },
            API: {
                endpoints: [
                    {
                        name: 'todoApi',
                        endpoint: API_GATEWAY_URL.replace('/todos', ''), // Base URL of your API Gateway
                        custom_header: async () => {
                            try {
                                const session = await window.Auth.currentSession();
                                return { Authorization: session.getIdToken().getJwtToken() };
                            } catch (e) {
                                console.error("No current session, returning empty headers.");
                                return {};
                            }
                        },
                    },
                ],
            },
        });
        checkCurrentUser();
    } else {
        showMessage("Error: AWS Amplify libraries or configuration variables not available. Please ensure CDN loaded correctly and variables are set in index.html.", true);
    }
}

// --- Authentication Functions ---
async function checkCurrentUser() {
    try {
        const currentUser = await window.Auth.currentAuthenticatedUser();
        showAppSection(currentUser);
    } catch (e) {
        console.log("No authenticated user:", e);
        showAuthSection('signin'); // Default to sign-in form
    }
}

async function handleSignUp() {
    const email = signUpEmailInput.value;
    const password = signUpPasswordInput.value;
    currentEmail = email; // Store email for confirmation step
    if (!email || !password) {
        showMessage('Please enter both email and password.', true);
        return;
    }
    try {
        await window.Auth.signUp({
            username: email,
            password,
            attributes: { email }
        });
        showMessage('Sign up successful! Please check your email for a verification code.');
        showAuthSection('confirmSignUp');
    } catch (error) {
        console.error('Error signing up:', error);
        showMessage(`Sign Up Error: ${error.message}`, true);
    }
}

async function handleConfirmSignUp() {
    const code = confirmCodeInput.value;
    if (!code) {
        showMessage('Please enter the verification code.', true);
        return;
    }
    try {
        await window.Auth.confirmSignUp(currentEmail, code);
        showMessage('Account confirmed! You can now sign in.');
        showAuthSection('signin');
        // Auto-fill sign-in fields
        signInEmailInput.value = currentEmail;
        signInPasswordInput.value = ''; // Don't autofill password for security
    } catch (error) {
        console.error('Error confirming sign up:', error);
        showMessage(`Confirmation Error: ${error.message}`, true);
    }
}

async function handleSignIn() {
    const email = signInEmailInput.value;
    const password = signInPasswordInput.value;
    if (!email || !password) {
        showMessage('Please enter both email and password.', true);
        return;
    }
    try {
        const user = await window.Auth.signIn(email, password);
        showMessage('Successfully signed in!');
        showAppSection(user);
    } catch (error) {
        console.error('Error signing in:', error);
        showMessage(`Sign In Error: ${error.message}`, true);
    }
}

async function handleSignOut() {
    try {
        await window.Auth.signOut();
        showMessage('You have been signed out.');
        showAuthSection('signin');
        todoList.innerHTML = ''; // Clear To-Do list on sign out
        noTodosMessage.classList.remove('hidden');
        newTodoTaskInput.value = '';
        signUpEmailInput.value = '';
        signUpPasswordInput.value = '';
        signInEmailInput.value = '';
        signInPasswordInput.value = '';
    } catch (error) {
        console.error('Error signing out:', error);
        showMessage(`Sign Out Error: ${error.message}`, true);
    }
}

// --- API Interaction Functions ---
async function getAuthHeaders() {
    try {
        const session = await window.Auth.currentSession();
        return { Authorization: session.getIdToken().getJwtToken() };
    } catch (e) {
        console.error("Authentication required:", e);
        showMessage('Your session has expired. Please sign in again.', true);
        handleSignOut(); // Force sign out if session is invalid
        throw new Error('Authentication required');
    }
}

function renderTodos(todos) {
    todoList.innerHTML = ''; // Clear existing list
    if (todos.length === 0) {
        noTodosMessage.classList.remove('hidden');
        return;
    }
    noTodosMessage.classList.add('hidden');

    todos.forEach(todo => {
        const listItem = document.createElement('li');
        listItem.className = 'flex items-center justify-between bg-gray-50 p-4 rounded-lg shadow-sm border border-gray-200';
        listItem.innerHTML = `
            <span class="flex-grow text-gray-800 ${todo.completed ? 'line-through text-gray-500' : ''}">
                ${todo.task}
                ${todo.dueDate ? `<span class="ml-2 text-xs text-gray-400"> (Due: ${new Date(todo.dueDate).toLocaleDateString()})</span>` : ''}
                ${todo.category ? `<span class="ml-2 text-xs text-gray-400"> (${todo.category})</span>` : ''}
                ${todo.priority ? `<span class="ml-2 text-xs font-semibold text-blue-500 capitalize">(${todo.priority})</span>` : ''}
            </span>
            <div class="flex items-center space-x-2 ml-4">
                <button
                    class="toggle-completed-button p-2 rounded-full transition duration-150 ease-in-out ${todo.completed ? 'bg-green-500 hover:bg-green-600' : 'bg-yellow-500 hover:bg-yellow-600'} text-white shadow-md"
                    title="${todo.completed ? 'Mark as Incomplete' : 'Mark as Complete'}"
                    data-todo-id="${todo.id}"
                    data-todo-completed="${todo.completed}"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        ${todo.completed ? `
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />` : `
                        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L10.586 12 13.293 9.293a1 1 0 00-1.414-1.414L10 10.586 8.707 7.293z" clip-rule="evenodd" />`}
                    </svg>
                </button>
                <button
                    class="delete-todo-button p-2 bg-red-500 text-white rounded-full hover:bg-red-600 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition duration-150 ease-in-out shadow-md"
                    title="Delete To-Do"
                    data-todo-id="${todo.id}"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm6 0a1 1 0 11-2 0v6a1 1 0 112 0V8z" clip-rule="evenodd" />
                    </svg>
                </button>
            </div>
        `;
        todoList.appendChild(listItem);
    });

    // Add event listeners to newly rendered buttons
    document.querySelectorAll('.toggle-completed-button').forEach(button => {
        button.addEventListener('click', (event) => {
            const id = event.currentTarget.dataset.todoId;
            const completed = event.currentTarget.dataset.todoCompleted === 'true'; // Convert string to boolean
            updateTodo(id, completed);
        });
    });

    document.querySelectorAll('.delete-todo-button').forEach(button => {
        button.addEventListener('click', (event) => {
            const id = event.currentTarget.dataset.todoId;
            deleteTodo(id);
        });
    });
}

async function fetchTodos() {
    showMessage(''); // Clear previous messages
    try {
        const headers = await getAuthHeaders();
        const response = await fetch(`${API_GATEWAY_URL}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...headers,
            },
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
            throw new Error(`Error fetching todos: ${response.status} ${errorData.message || response.statusText}`);
        }

        const data = await response.json();
        renderTodos(data);
    } catch (error) {
        console.error('Error fetching todos:', error);
        showMessage(`Error fetching To-Dos: ${error.message}`, true);
    }
}

async function createTodo() {
    showMessage('');
    const task = newTodoTaskInput.value.trim();
    if (!task) {
        showMessage('To-Do task cannot be empty.', true);
        return;
    }

    try {
        const headers = await getAuthHeaders();
        const response = await fetch(`${API_GATEWAY_URL}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                ...headers,
            },
            body: JSON.stringify({ task: task }), // Only sending task for simplicity
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
            throw new Error(`Error creating todo: ${response.status} ${errorData.message || response.statusText}`);
        }

        newTodoTaskInput.value = ''; // Clear input
        showMessage('To-Do created successfully!');
        fetchTodos(); // Re-fetch to update the list
    } catch (error) {
        console.error('Error creating todo:', error);
        showMessage(`Error creating To-Do: ${error.message}`, true);
    }
}

async function updateTodo(id, currentCompleted) {
    showMessage('');
    try {
        const headers = await getAuthHeaders();
        const response = await fetch(`${API_GATEWAY_URL}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                ...headers,
            },
            body: JSON.stringify({ completed: !currentCompleted }), // Toggle completed status
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
            throw new Error(`Error updating todo: ${response.status} ${errorData.message || response.statusText}`);
        }

        showMessage('To-Do updated successfully!');
        fetchTodos(); // Re-fetch to update the list
    } catch (error) {
        console.error('Error updating todo:', error);
        showMessage(`Error updating To-Do: ${error.message}`, true);
    }
}

async function deleteTodo(id) {
    showMessage('');
    try {
        const headers = await getAuthHeaders();
        const response = await fetch(`${API_GATEWAY_URL}/${id}`, {
            method: 'DELETE',
            headers: headers,
        });

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({ message: 'Unknown error' }));
            throw new Error(`Error deleting todo: ${response.status} ${errorData.message || response.statusText}`);
        }

        showMessage('To-Do deleted successfully!');
        fetchTodos(); // Re-fetch to update the list
    } catch (error) {
        console.error('Error deleting todo:', error);
        showMessage(`Error deleting To-Do: ${error.message}`, true);
    }
}

// --- Event Listeners ---
document.addEventListener('DOMContentLoaded', () => {
    // Initial Amplify config and check user after DOM is ready
    configureAmplify();
});

// Authentication Buttons
signUpButton.addEventListener('click', handleSignUp);
showSignInButton.addEventListener('click', () => showAuthSection('signin'));
confirmSignUpButton.addEventListener('click', handleConfirmSignUp);
signInButton.addEventListener('click', handleSignIn);
showSignUpButton.addEventListener('click', () => showAuthSection('signup'));
signOutButton.addEventListener('click', handleSignOut);

// To-Do App Buttons
addTodoButton.addEventListener('click', createTodo);
newTodoTaskInput.addEventListener('keypress', (event) => {
    if (event.key === 'Enter') {
        createTodo();
    }
});